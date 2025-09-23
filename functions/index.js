const functions = require('firebase-functions');
const admin = require('firebase-admin');
const turf = require('@turf/boolean-point-in-polygon');
const { point, polygon } = require('@turf/helpers');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function triggered when a new issue is created
 * Automatically assigns the issue to the appropriate local authority
 */
exports.assignIssueToAuthority = functions.firestore
  .document('issues/{issueId}')
  .onCreate(async (snap, context) => {
    const issueId = context.params.issueId;
    const issueData = snap.data();
    
    console.log(`Processing issue ${issueId}:`, issueData);
    
    try {
      const { latitude, longitude, pincode, address } = issueData;
      
      if (!latitude || !longitude) {
        console.error(`Issue ${issueId} missing coordinates`);
        return null;
      }
      
      // Step 1: Try pincode-based assignment (primary method)
      let assignedAuthority = await assignByPincode(pincode);
      let assignmentMethod = 'pincode';
      
      // Step 2: If no pincode match, try polygon containment
      if (!assignedAuthority) {
        assignedAuthority = await assignByPolygon(latitude, longitude);
        assignmentMethod = 'polygon';
      }
      
      // Step 3: If still no match, try nearest authority by distance
      if (!assignedAuthority) {
        assignedAuthority = await assignByDistance(latitude, longitude, address);
        assignmentMethod = 'distance';
      }
      
      // Step 4: Final fallback - state level or unassigned
      if (!assignedAuthority) {
        assignedAuthority = await assignByStateFallback(address);
        assignmentMethod = 'state_fallback';
      }
      
      const finalAssignment = assignedAuthority || 'UNASSIGNED';
      
      // Update the issue with assignment
      await snap.ref.update({
        assignedTo: finalAssignment,
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        assignmentMethod: assignmentMethod,
      });
      
      console.log(`Issue ${issueId} assigned to ${finalAssignment} via ${assignmentMethod}`);
      
      // Send FCM notification to authority if assigned
      if (assignedAuthority && assignedAuthority !== 'UNASSIGNED') {
        await sendNotificationToAuthority(assignedAuthority, issueId, issueData);
      }
      
      // Log assignment for monitoring
      await logAssignment(issueId, finalAssignment, assignmentMethod, {
        pincode,
        latitude,
        longitude,
        address,
      });
      
      return null;
      
    } catch (error) {
      console.error(`Error processing issue ${issueId}:`, error);
      
      // Mark as unassigned on error
      await snap.ref.update({
        assignedTo: 'UNASSIGNED',
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        assignmentMethod: 'error',
        assignmentError: error.message,
      });
      
      return null;
    }
  });

/**
 * Assign issue by pincode matching
 */
async function assignByPincode(pincode) {
  if (!pincode || pincode.trim() === '') {
    console.log('No pincode provided');
    return null;
  }
  
  console.log(`Searching authorities by pincode: ${pincode}`);
  
  try {
    const authoritiesSnapshot = await db.collection('authorities')
      .where('pincodes', 'array-contains', pincode.trim())
      .limit(1)
      .get();
    
    if (!authoritiesSnapshot.empty) {
      const authority = authoritiesSnapshot.docs[0];
      console.log(`Found authority by pincode: ${authority.id}`);
      return authority.id;
    }
    
    console.log(`No authority found for pincode: ${pincode}`);
    return null;
    
  } catch (error) {
    console.error('Error in pincode assignment:', error);
    return null;
  }
}

/**
 * Assign issue by polygon containment
 */
async function assignByPolygon(latitude, longitude) {
  console.log(`Searching authorities by polygon containment: ${latitude}, ${longitude}`);
  
  try {
    const authoritiesSnapshot = await db.collection('authorities')
      .where('polygon', '!=', null)
      .get();
    
    const issuePoint = point([longitude, latitude]);
    
    for (const doc of authoritiesSnapshot.docs) {
      const authorityData = doc.data();
      
      if (authorityData.polygon && Array.isArray(authorityData.polygon)) {
        try {
          // Convert polygon format: [[lat, lng], ...] to [[lng, lat], ...]
          const polygonCoords = authorityData.polygon.map(coord => [coord[1], coord[0]]);
          const authorityPolygon = polygon([polygonCoords]);
          
          if (turf(issuePoint, authorityPolygon)) {
            console.log(`Found authority by polygon: ${doc.id}`);
            return doc.id;
          }
        } catch (polygonError) {
          console.error(`Error checking polygon for authority ${doc.id}:`, polygonError);
        }
      }
    }
    
    console.log('No authority found by polygon containment');
    return null;
    
  } catch (error) {
    console.error('Error in polygon assignment:', error);
    return null;
  }
}

/**
 * Assign issue by distance to nearest authority center
 */
async function assignByDistance(latitude, longitude, address) {
  console.log(`Searching authorities by distance: ${latitude}, ${longitude}`);
  
  try {
    const authoritiesSnapshot = await db.collection('authorities').get();
    
    let nearestAuthority = null;
    let minDistance = Infinity;
    const maxDistanceKm = 50; // Maximum 50km radius
    
    authoritiesSnapshot.forEach(doc => {
      const authorityData = doc.data();
      
      if (authorityData.center && authorityData.center._latitude !== undefined) {
        const distance = calculateDistance(
          latitude,
          longitude,
          authorityData.center._latitude,
          authorityData.center._longitude
        );
        
        if (distance < minDistance && distance <= maxDistanceKm) {
          minDistance = distance;
          nearestAuthority = doc.id;
        }
      }
    });
    
    if (nearestAuthority) {
      console.log(`Found nearest authority: ${nearestAuthority} at ${minDistance.toFixed(2)}km`);
      return nearestAuthority;
    }
    
    console.log('No authority found within distance threshold');
    return null;
    
  } catch (error) {
    console.error('Error in distance assignment:', error);
    return null;
  }
}

/**
 * Fallback to state-level authority
 */
async function assignByStateFallback(address) {
  console.log(`Searching state-level authority for address: ${address}`);
  
  try {
    // Extract state from address (simplified - in production use proper parsing)
    const addressLower = address.toLowerCase();
    let state = null;
    
    const stateKeywords = {
      'tamil nadu': 'TN',
      'karnataka': 'KA',
      'kerala': 'KL',
      'andhra pradesh': 'AP',
      'telangana': 'TS',
      'maharashtra': 'MH',
      'gujarat': 'GJ',
      'rajasthan': 'RJ',
      'uttar pradesh': 'UP',
      'madhya pradesh': 'MP',
      'west bengal': 'WB',
      'bihar': 'BR',
      'odisha': 'OR',
      'jharkhand': 'JH',
      'assam': 'AS',
      'punjab': 'PB',
      'haryana': 'HR',
      'himachal pradesh': 'HP',
      'uttarakhand': 'UK',
      'goa': 'GA',
      'delhi': 'DL',
    };
    
    for (const [stateName, stateCode] of Object.entries(stateKeywords)) {
      if (addressLower.includes(stateName)) {
        state = stateCode;
        break;
      }
    }
    
    if (state) {
      // Look for state-level authority
      const stateAuthoritySnapshot = await db.collection('authorities')
        .where('state', '==', state)
        .where('name', '>=', 'State')
        .limit(1)
        .get();
      
      if (!stateAuthoritySnapshot.empty) {
        const stateAuthority = stateAuthoritySnapshot.docs[0].id;
        console.log(`Found state-level authority: ${stateAuthority}`);
        return stateAuthority;
      }
    }
    
    console.log('No state-level authority found');
    return null;
    
  } catch (error) {
    console.error('Error in state fallback assignment:', error);
    return null;
  }
}

/**
 * Send FCM notification to authority
 */
async function sendNotificationToAuthority(authorityId, issueId, issueData) {
  try {
    const authorityDoc = await db.collection('authorities').doc(authorityId).get();
    
    if (!authorityDoc.exists) {
      console.error(`Authority ${authorityId} not found`);
      return;
    }
    
    const authorityData = authorityDoc.data();
    const fcmTokens = authorityData.fcmTokens || [];
    
    if (fcmTokens.length === 0) {
      console.log(`No FCM tokens for authority ${authorityId}`);
      return;
    }
    
    const message = {
      notification: {
        title: 'New Civic Issue Assigned',
        body: `New issue reported at ${issueData.address}`,
      },
      data: {
        issueId: issueId,
        authorityId: authorityId,
        latitude: issueData.latitude.toString(),
        longitude: issueData.longitude.toString(),
        address: issueData.address,
        imageUrl: issueData.imageUrl || '',
      },
    };
    
    // Send to all tokens
    const responses = await Promise.allSettled(
      fcmTokens.map(token => messaging.sendToDevice(token, message))
    );
    
    console.log(`Sent notifications to ${fcmTokens.length} devices for authority ${authorityId}`);
    
    // Clean up invalid tokens
    const invalidTokens = [];
    responses.forEach((response, index) => {
      if (response.status === 'rejected' || 
          (response.value && response.value.failureCount > 0)) {
        invalidTokens.push(fcmTokens[index]);
      }
    });
    
    if (invalidTokens.length > 0) {
      const validTokens = fcmTokens.filter(token => !invalidTokens.includes(token));
      await authorityDoc.ref.update({ fcmTokens: validTokens });
      console.log(`Removed ${invalidTokens.length} invalid FCM tokens`);
    }
    
  } catch (error) {
    console.error('Error sending FCM notification:', error);
  }
}

/**
 * Log assignment for monitoring and analytics
 */
async function logAssignment(issueId, assignedTo, method, metadata) {
  try {
    await db.collection('assignment_logs').add({
      issueId,
      assignedTo,
      method,
      metadata,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Error logging assignment:', error);
  }
}

/**
 * Calculate distance between two points using Haversine formula
 */
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

/**
 * HTTP function to manually reassign an issue (for admin use)
 */
exports.reassignIssue = functions.https.onCall(async (data, context) => {
  // Verify admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const { issueId, newAuthorityId } = data;
  
  if (!issueId || !newAuthorityId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing issueId or newAuthorityId');
  }
  
  try {
    await db.collection('issues').doc(issueId).update({
      assignedTo: newAuthorityId,
      reassignedAt: admin.firestore.FieldValue.serverTimestamp(),
      reassignedBy: context.auth.uid,
    });
    
    return { success: true, message: `Issue ${issueId} reassigned to ${newAuthorityId}` };
    
  } catch (error) {
    console.error('Error reassigning issue:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reassign issue');
  }
});
