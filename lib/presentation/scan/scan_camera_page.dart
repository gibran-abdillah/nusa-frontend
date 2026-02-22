import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/datasources/scan_remote_datasource.dart';
import '../details/details_page.dart';

class ScanCameraPage extends StatefulWidget {
  final String imagePath;

  const ScanCameraPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage> {
  final _scanDataSource = ScanRemoteDataSource();
  String _mealType = 'lunch';
  bool _isLoading = false;
  String _statusText = '';

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  Future<void> _processImage() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Uploading image...';
    });

    final file = File(widget.imagePath);

    // 1. Upload
    final prepareRes = await _scanDataSource.uploadAndPrepareScan(
      imageFile: file,
    );

    if (!prepareRes.success || prepareRes.data == null) {
      _showError('Failed to prepare scan: ${prepareRes.message}');
      return;
    }

    if (!mounted) return;
    setState(() {
      _statusText = 'Analyzing food...';
    });

    final scanId = prepareRes.data!.scanId;

    // 2. Analyze
    final analyzeRes = await _scanDataSource.analyzeScan(
      scanId: scanId,
      mealType: _mealType,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    if (analyzeRes.success && analyzeRes.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image analyzed successfully!')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              DetailsPage(log: analyzeRes.data!, isFromUpload: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis rejected: ${analyzeRes.message}'),
          backgroundColor: AppTheme.redAccent,
        ),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Dark background looks better for camera captures
      appBar: AppBar(
        title: const Text(
          'Review Food Image',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.file(File(widget.imagePath), fit: BoxFit.cover),

          // Bottom Controls overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Meal Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mealType,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: _mealTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textBlack,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _mealType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _processImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Analyze Food',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
