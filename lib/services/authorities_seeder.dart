import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/authority.dart';

class AuthoritiesSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seeds sample authorities data into Firestore
  static Future<void> seedSampleAuthorities() async {
    try {
      print('Starting to seed sample authorities...');

      final List<Authority> sampleAuthorities = [
        // Tamil Nadu - Chennai
        Authority(
          id: 'tn_chennai_greater_corp',
          name: 'Greater Chennai Corporation',
          state: 'TN',
          district: 'Chennai',
          pincodes: ['600001', '600002', '600003', '600004', '600005', '600006', 
                    '600007', '600008', '600009', '600010', '600011', '600012',
                    '600013', '600014', '600015', '600016', '600017', '600018',
                    '600019', '600020', '600021', '600022', '600023', '600024',
                    '600025', '600026', '600028', '600029', '600030', '600031',
                    '600032', '600033', '600034', '600035', '600036', '600037',
                    '600038', '600039', '600040', '600041', '600042', '600043',
                    '600044', '600045', '600046', '600047', '600048', '600049',
                    '600050', '600051', '600052', '600053', '600054', '600055',
                    '600056', '600057', '600058', '600059', '600060', '600061',
                    '600062', '600063', '600064', '600065', '600066', '600067',
                    '600068', '600069', '600070', '600071', '600072', '600073',
                    '600074', '600075', '600076', '600077', '600078', '600079',
                    '600080', '600081', '600082', '600083', '600084', '600085',
                    '600086', '600087', '600088', '600089', '600090', '600091',
                    '600092', '600093', '600094', '600095', '600096', '600097',
                    '600098', '600099', '600100', '600101', '600102', '600103',
                    '600104', '600105', '600106', '600107', '600108', '600109',
                    '600110', '600111', '600112', '600113', '600114', '600115',
                    '600116', '600117', '600118', '600119', '600120', '600121',
                    '600122', '600123', '600124', '600125', '600126', '600127',
                    '600128', '600129', '600130'],
          center: const GeoPoint(13.0827, 80.2707),
          adminUserId: 'chennai_admin_001',
          fcmTokens: [],
        ),

        // Karnataka - Bangalore
        Authority(
          id: 'ka_bangalore_bbmp',
          name: 'Bruhat Bengaluru Mahanagara Palike (BBMP)',
          state: 'KA',
          district: 'Bangalore Urban',
          pincodes: ['560001', '560002', '560003', '560004', '560005', '560006',
                    '560007', '560008', '560009', '560010', '560011', '560012',
                    '560013', '560014', '560015', '560016', '560017', '560018',
                    '560019', '560020', '560021', '560022', '560023', '560024',
                    '560025', '560026', '560027', '560028', '560029', '560030',
                    '560031', '560032', '560033', '560034', '560035', '560036',
                    '560037', '560038', '560039', '560040', '560041', '560042',
                    '560043', '560044', '560045', '560046', '560047', '560048',
                    '560049', '560050', '560051', '560052', '560053', '560054',
                    '560055', '560056', '560057', '560058', '560059', '560060',
                    '560061', '560062', '560063', '560064', '560065', '560066',
                    '560067', '560068', '560069', '560070', '560071', '560072',
                    '560073', '560074', '560075', '560076', '560077', '560078',
                    '560079', '560080', '560081', '560082', '560083', '560084',
                    '560085', '560086', '560087', '560088', '560089', '560090',
                    '560091', '560092', '560093', '560094', '560095', '560096',
                    '560097', '560098', '560099', '560100'],
          center: const GeoPoint(12.9716, 77.5946),
          adminUserId: 'bangalore_admin_001',
          fcmTokens: [],
        ),

        // Maharashtra - Mumbai
        Authority(
          id: 'mh_mumbai_bmc',
          name: 'Brihanmumbai Municipal Corporation (BMC)',
          state: 'MH',
          district: 'Mumbai',
          pincodes: ['400001', '400002', '400003', '400004', '400005', '400006',
                    '400007', '400008', '400009', '400010', '400011', '400012',
                    '400013', '400014', '400015', '400016', '400017', '400018',
                    '400019', '400020', '400021', '400022', '400023', '400024',
                    '400025', '400026', '400027', '400028', '400029', '400030',
                    '400031', '400032', '400033', '400034', '400035', '400036',
                    '400037', '400038', '400039', '400040', '400041', '400042',
                    '400043', '400044', '400045', '400046', '400047', '400048',
                    '400049', '400050', '400051', '400052', '400053', '400054',
                    '400055', '400056', '400057', '400058', '400059', '400060',
                    '400061', '400062', '400063', '400064', '400065', '400066',
                    '400067', '400068', '400069', '400070', '400071', '400072',
                    '400074', '400075', '400076', '400077', '400078', '400079',
                    '400080', '400081', '400082', '400083', '400084', '400085',
                    '400086', '400087', '400088', '400089', '400090', '400091',
                    '400092', '400093', '400094', '400095', '400096', '400097',
                    '400098', '400099', '400101', '400102', '400103', '400104'],
          center: const GeoPoint(19.0760, 72.8777),
          adminUserId: 'mumbai_admin_001',
          fcmTokens: [],
        ),

        // Delhi - New Delhi Municipal Council
        Authority(
          id: 'dl_newdelhi_ndmc',
          name: 'New Delhi Municipal Council (NDMC)',
          state: 'DL',
          district: 'New Delhi',
          pincodes: ['110001', '110002', '110003', '110004', '110005', '110006',
                    '110007', '110008', '110009', '110010', '110011', '110012',
                    '110013', '110014', '110015', '110016', '110017', '110018',
                    '110019', '110020', '110021', '110022', '110023', '110024',
                    '110025', '110026', '110027', '110028', '110029', '110030',
                    '110031', '110032', '110033', '110034', '110035', '110036',
                    '110037', '110038', '110039', '110040', '110041', '110042',
                    '110043', '110044', '110045', '110046', '110047', '110048',
                    '110049', '110050', '110051', '110052', '110053', '110054',
                    '110055', '110056', '110057', '110058', '110059', '110060',
                    '110061', '110062', '110063', '110064', '110065', '110066',
                    '110067', '110068', '110069', '110070', '110071', '110072',
                    '110073', '110074', '110075', '110076', '110077', '110078',
                    '110079', '110080', '110081', '110082', '110083', '110084',
                    '110085', '110086', '110087', '110088', '110089', '110090',
                    '110091', '110092', '110093', '110094', '110095', '110096'],
          center: const GeoPoint(28.6139, 77.2090),
          adminUserId: 'delhi_admin_001',
          fcmTokens: [],
        ),

        // Uttar Pradesh - Lucknow
        Authority(
          id: 'up_lucknow_lmc',
          name: 'Lucknow Municipal Corporation',
          state: 'UP',
          district: 'Lucknow',
          pincodes: ['226001', '226002', '226003', '226004', '226005', '226006',
                    '226007', '226008', '226009', '226010', '226011', '226012',
                    '226013', '226014', '226015', '226016', '226017', '226018',
                    '226019', '226020', '226021', '226022', '226023', '226024',
                    '226025', '226026', '226027', '226028', '226029', '226030'],
          center: const GeoPoint(26.8467, 80.9462),
          adminUserId: 'lucknow_admin_001',
          fcmTokens: [],
        ),

        // State-level fallback authorities
        Authority(
          id: 'tn_state_authority',
          name: 'Tamil Nadu State Urban Development Authority',
          state: 'TN',
          district: 'State Level',
          pincodes: [], // State level - no specific pincodes
          center: const GeoPoint(13.0827, 80.2707),
          adminUserId: 'tn_state_admin_001',
          fcmTokens: [],
        ),

        Authority(
          id: 'ka_state_authority',
          name: 'Karnataka State Urban Development Authority',
          state: 'KA',
          district: 'State Level',
          pincodes: [],
          center: const GeoPoint(12.9716, 77.5946),
          adminUserId: 'ka_state_admin_001',
          fcmTokens: [],
        ),

        Authority(
          id: 'mh_state_authority',
          name: 'Maharashtra State Urban Development Authority',
          state: 'MH',
          district: 'State Level',
          pincodes: [],
          center: const GeoPoint(19.0760, 72.8777),
          adminUserId: 'mh_state_admin_001',
          fcmTokens: [],
        ),
      ];

      // Add authorities to Firestore
      for (final authority in sampleAuthorities) {
        await _firestore
            .collection('authorities')
            .doc(authority.id)
            .set(authority.toFirestore());
        
        print('Added authority: ${authority.name}');
      }

      // Create admin user mappings
      final List<Map<String, String>> adminMappings = [
        {'userId': 'chennai_admin_001', 'authorityId': 'tn_chennai_greater_corp'},
        {'userId': 'bangalore_admin_001', 'authorityId': 'ka_bangalore_bbmp'},
        {'userId': 'mumbai_admin_001', 'authorityId': 'mh_mumbai_bmc'},
        {'userId': 'delhi_admin_001', 'authorityId': 'dl_newdelhi_ndmc'},
        {'userId': 'lucknow_admin_001', 'authorityId': 'up_lucknow_lmc'},
        {'userId': 'tn_state_admin_001', 'authorityId': 'tn_state_authority'},
        {'userId': 'ka_state_admin_001', 'authorityId': 'ka_state_authority'},
        {'userId': 'mh_state_admin_001', 'authorityId': 'mh_state_authority'},
      ];

      for (final mapping in adminMappings) {
        await _firestore
            .collection('admins')
            .doc(mapping['userId']!)
            .set({
          'authorityId': mapping['authorityId'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('Added admin mapping: ${mapping['userId']} -> ${mapping['authorityId']}');
      }

      print('Successfully seeded ${sampleAuthorities.length} authorities and ${adminMappings.length} admin mappings');
      
    } catch (e) {
      print('Error seeding authorities: $e');
      rethrow;
    }
  }

  /// Clears all authorities and admin mappings (use with caution)
  static Future<void> clearAllAuthorities() async {
    try {
      print('Clearing all authorities...');
      
      // Delete all authorities
      final authoritiesSnapshot = await _firestore.collection('authorities').get();
      for (final doc in authoritiesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete all admin mappings
      final adminsSnapshot = await _firestore.collection('admins').get();
      for (final doc in adminsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      print('Cleared all authorities and admin mappings');
      
    } catch (e) {
      print('Error clearing authorities: $e');
      rethrow;
    }
  }
}
