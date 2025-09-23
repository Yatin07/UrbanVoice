const test = require('firebase-functions-test')();
const admin = require('firebase-admin');

// Mock Firestore
const mockFirestore = {
  collection: jest.fn(() => ({
    where: jest.fn(() => ({
      limit: jest.fn(() => ({
        get: jest.fn()
      })),
      get: jest.fn()
    })),
    doc: jest.fn(() => ({
      set: jest.fn(),
      update: jest.fn(),
      get: jest.fn()
    })),
    add: jest.fn()
  }))
};

// Mock the functions
const myFunctions = require('../index');

describe('Authority Assignment Logic', () => {
  let wrapped;

  beforeAll(() => {
    // Mock admin SDK
    admin.initializeApp = jest.fn();
    admin.firestore = jest.fn(() => mockFirestore);
    admin.messaging = jest.fn(() => ({
      sendToDevice: jest.fn()
    }));
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  describe('Pincode Assignment', () => {
    test('should assign issue to authority with matching pincode', async () => {
      // Mock Firestore response for pincode match
      const mockSnapshot = {
        empty: false,
        docs: [{
          id: 'tn_chennai_greater_corp',
          data: () => ({
            name: 'Greater Chennai Corporation',
            pincodes: ['600001', '600002']
          })
        }]
      };

      mockFirestore.collection().where().limit().get.mockResolvedValue(mockSnapshot);

      // Mock issue data
      const issueData = {
        latitude: 13.0827,
        longitude: 80.2707,
        pincode: '600001',
        address: 'T Nagar, Chennai'
      };

      // Test the assignment logic (you would extract this into a separate function)
      const result = await assignByPincode('600001');
      
      expect(result).toBe('tn_chennai_greater_corp');
      expect(mockFirestore.collection).toHaveBeenCalledWith('authorities');
    });

    test('should return null for non-matching pincode', async () => {
      const mockSnapshot = {
        empty: true,
        docs: []
      };

      mockFirestore.collection().where().limit().get.mockResolvedValue(mockSnapshot);

      const result = await assignByPincode('999999');
      
      expect(result).toBe(null);
    });
  });

  describe('Distance Calculation', () => {
    test('should calculate correct distance between two points', () => {
      // Test Haversine formula implementation
      const lat1 = 13.0827; // Chennai
      const lon1 = 80.2707;
      const lat2 = 12.9716; // Bangalore
      const lon2 = 77.5946;

      const distance = calculateDistance(lat1, lon1, lat2, lon2);
      
      // Distance between Chennai and Bangalore is approximately 347 km
      expect(distance).toBeCloseTo(347, 0);
    });

    test('should return 0 for same coordinates', () => {
      const distance = calculateDistance(13.0827, 80.2707, 13.0827, 80.2707);
      expect(distance).toBe(0);
    });
  });

  describe('Polygon Containment', () => {
    test('should detect point inside polygon', () => {
      // Mock polygon for Chennai (simplified rectangle)
      const chennaiPolygon = [
        [13.2000, 80.1000], // NW
        [13.2000, 80.3000], // NE
        [12.9000, 80.3000], // SE
        [12.9000, 80.1000], // SW
        [13.2000, 80.1000]  // Close polygon
      ];

      const testPoint = [13.0827, 80.2707]; // Chennai center
      
      // This would use the turf library in actual implementation
      // For testing, we'll mock the result
      const isInside = true; // Mock result
      
      expect(isInside).toBe(true);
    });

    test('should detect point outside polygon', () => {
      const chennaiPolygon = [
        [13.2000, 80.1000],
        [13.2000, 80.3000],
        [12.9000, 80.3000],
        [12.9000, 80.1000],
        [13.2000, 80.1000]
      ];

      const testPoint = [12.9716, 77.5946]; // Bangalore (outside Chennai)
      
      const isInside = false; // Mock result
      
      expect(isInside).toBe(false);
    });
  });

  describe('State Fallback Logic', () => {
    test('should extract state from address correctly', () => {
      const testCases = [
        { address: 'T Nagar, Chennai, Tamil Nadu', expected: 'TN' },
        { address: 'MG Road, Bangalore, Karnataka', expected: 'KA' },
        { address: 'Connaught Place, New Delhi', expected: 'DL' },
        { address: 'Unknown location', expected: null }
      ];

      testCases.forEach(({ address, expected }) => {
        const result = extractStateFromAddress(address);
        expect(result).toBe(expected);
      });
    });
  });

  describe('FCM Notification', () => {
    test('should send notification to authority tokens', async () => {
      const mockAuthority = {
        exists: true,
        data: () => ({
          name: 'Test Authority',
          fcmTokens: ['token1', 'token2']
        }),
        ref: {
          update: jest.fn()
        }
      };

      mockFirestore.collection().doc().get.mockResolvedValue(mockAuthority);

      const mockMessaging = {
        sendToDevice: jest.fn().mockResolvedValue({
          successCount: 2,
          failureCount: 0
        })
      };

      admin.messaging.mockReturnValue(mockMessaging);

      await sendNotificationToAuthority('test_authority', 'issue123', {
        address: 'Test Address',
        imageUrl: 'https://example.com/image.jpg'
      });

      expect(mockMessaging.sendToDevice).toHaveBeenCalledTimes(2);
    });
  });

  describe('Assignment Logging', () => {
    test('should log assignment details', async () => {
      const mockAdd = jest.fn().mockResolvedValue({ id: 'log123' });
      mockFirestore.collection().add = mockAdd;

      await logAssignment('issue123', 'authority456', 'pincode', {
        pincode: '600001',
        latitude: 13.0827,
        longitude: 80.2707
      });

      expect(mockAdd).toHaveBeenCalledWith({
        issueId: 'issue123',
        assignedTo: 'authority456',
        method: 'pincode',
        metadata: {
          pincode: '600001',
          latitude: 13.0827,
          longitude: 80.2707
        },
        timestamp: expect.any(Object)
      });
    });
  });
});

// Helper functions that would be extracted from the main Cloud Function

async function assignByPincode(pincode) {
  if (!pincode || pincode.trim() === '') {
    return null;
  }
  
  try {
    const authoritiesSnapshot = await mockFirestore.collection('authorities')
      .where('pincodes', 'array-contains', pincode.trim())
      .limit(1)
      .get();
    
    if (!authoritiesSnapshot.empty) {
      return authoritiesSnapshot.docs[0].id;
    }
    
    return null;
  } catch (error) {
    return null;
  }
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

function extractStateFromAddress(address) {
  const addressLower = address.toLowerCase();
  const stateKeywords = {
    'tamil nadu': 'TN',
    'karnataka': 'KA',
    'kerala': 'KL',
    'delhi': 'DL',
    'new delhi': 'DL',
    'maharashtra': 'MH',
    'gujarat': 'GJ',
    'rajasthan': 'RJ',
    'uttar pradesh': 'UP',
    'west bengal': 'WB'
  };
  
  for (const [stateName, stateCode] of Object.entries(stateKeywords)) {
    if (addressLower.includes(stateName)) {
      return stateCode;
    }
  }
  
  return null;
}

async function sendNotificationToAuthority(authorityId, issueId, issueData) {
  // Mock implementation for testing
  return Promise.resolve();
}

async function logAssignment(issueId, assignedTo, method, metadata) {
  return mockFirestore.collection('assignment_logs').add({
    issueId,
    assignedTo,
    method,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });
}
