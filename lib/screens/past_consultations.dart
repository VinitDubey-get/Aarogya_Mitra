import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'prescription.dart';

class PastConsultationsScreen extends StatefulWidget {
  const PastConsultationsScreen({Key? key}) : super(key: key);

  @override
  _PastConsultationsScreenState createState() => _PastConsultationsScreenState();
}

class _PastConsultationsScreenState extends State<PastConsultationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  List<DocumentSnapshot> _consultations = [];
  String _errorMessage = '';
  // bool _isDeleting = false;
  // String _deletingId = '';

  // Cache to store doctor information to avoid redundant fetches
  Map<String, String> _doctorCache = {};

  @override
  void initState() {
    super.initState();
    _fetchConsultations();
  }

  // Fetch doctor information from Firestore
  Future<String> _fetchDoctorName(String doctorId) async {
    // Check if doctor info is already in cache
    if (_doctorCache.containsKey(doctorId)) {
      return _doctorCache[doctorId]!;
    }

    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();

      if (doctorDoc.exists) {
        String doctorName = doctorDoc['name'] ?? 'Unknown Doctor';

        // Store in cache for future use
        _doctorCache[doctorId] = doctorName;
        return doctorName;
      } else {
        return 'Unknown Doctor';
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
      return 'Unknown Doctor';
    }
  }

  Future<void> _fetchConsultations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _consultations = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching consultations: $e';
      });
      print('Error fetching consultations: $e');
    }
  }

  Future<void> _deleteConsultation(String consultationId) async {
    // setState(() {
    //   _isDeleting = true;
    //   _deletingId = consultationId;
    // });

    try {
      await _firestore.collection('consultations').doc(consultationId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _fetchConsultations();
    } catch (e) {
      // setState(() {
      //   _isDeleting = false;
      //   _deletingId = '';
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting consultation: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      print('Error deleting consultation: $e');
    }
  }

  Future<bool> _confirmDelete() async {
    bool confirmDelete = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Consultation?'),
          content: Text(
              'This action cannot be undone. Are you sure you want to delete this consultation record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                confirmDelete = true;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('DELETE'),
            ),
          ],
        );
      },
    );
    return confirmDelete;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Consultations'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchConsultations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchConsultations,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No consultations found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your past consultation history will appear here',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        final consultation = _consultations[index].data() as Map<String, dynamic>;
        final consultationId = _consultations[index].id;
        return _buildConsultationCard(consultation, consultationId);
      },
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation, String consultationId) {
    String formattedDate = 'Date not available';
    if (consultation['createdAt'] != null) {
      try {
        Timestamp timestamp = consultation['createdAt'] as Timestamp;
        DateTime dateTime = timestamp.toDate();
        formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
      } catch (e) {
        print('Error formatting date: $e');
      }
    }

    bool hasPrescription = consultation.containsKey('prescription') &&
        consultation['prescription'] != null;

    // Get doctorId from consultation
    String doctorId = consultation['doctorId'] ?? '';

    String status = consultation['status'] ?? 'Unknown Status';
    IconData statusIcon;
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'completed':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'in progress':
        statusIcon = Icons.access_time;
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.info;
        statusColor = Colors.blue;
        break;
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // if (_isDeleting && _deletingId == consultationId)
            
          FutureBuilder<String>(
            // Fetch doctor name using doctorId
            future: doctorId.isNotEmpty ? _fetchDoctorName(doctorId) : Future.value('Unknown Doctor'),
            builder: (context, snapshot) {
              String doctorName = snapshot.data ?? 'Loading...';

              return ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.medical_services, color: Colors.blue[800], size: 30),
                ),
                title: Text(
                  'Consultation with Dr. $doctorName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(formattedDate, style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
          Divider(height: 0),
          ButtonBar(
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                        bool confirmed = await _confirmDelete();
                        if (confirmed) {
                          _deleteConsultation(consultationId);
                        }
                      },
              ),
              TextButton.icon(
                icon: Icon(Icons.info_outline),
                label: Text('Details'),
                onPressed: () {
                  _showConsultationDetails(consultation, consultationId);
                },
              ),
              if (hasPrescription)
                TextButton.icon(
                  icon: Icon(Icons.description),
                  label: Text('Prescription'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Prescription(consultationId: consultationId),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConsultationDetails(Map<String, dynamic> consultation, String consultationId) {
    // Get doctorId from consultation
    String doctorId = consultation['doctorId'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Consultation Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('ID', consultationId),
                FutureBuilder<String>(
                  future: doctorId.isNotEmpty ? _fetchDoctorName(doctorId) : Future.value('Unknown Doctor'),
                  builder: (context, snapshot) {
                    String doctorName = snapshot.connectionState == ConnectionState.waiting
                        ? 'Loading...'
                        : snapshot.data ?? 'Unknown Doctor';
                    return _buildDetailItem('Doctor', doctorName);
                  },
                ),
                _buildDetailItem('Status', consultation['status'] ?? 'Unknown'),
                _buildDetailItem('Chief Complaint', consultation['chiefComplaint'] ?? 'Not recorded'),
                if (consultation.containsKey('additionalNotes') && consultation['additionalNotes'] != null)
                  _buildDetailItem('Notes', consultation['additionalNotes']),
                if (consultation.containsKey('createdAt') && consultation['createdAt'] != null)
                  _buildDetailItem('Created', DateFormat('MMM dd, yyyy - hh:mm a').format((consultation['createdAt'] as Timestamp).toDate())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 4),
          Divider(),
        ],
      ),
    );
  }
}
