import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'models/bill_analysis.dart';
import 'screens/transaction_entry_screen.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  String _scannedText = '';
  File? _selectedImage;
  BillAnalysis? _billAnalysis;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to use the scanner'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras found on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isScanning = true;
      });

      final XFile image = await _cameraController!.takePicture();
      await _processImage(File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isScanning = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      setState(() {
        _selectedImage = imageFile;
        _scannedText = '';
        _billAnalysis = null;
      });

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }

      if (mounted) {
        setState(() {
          _scannedText = extractedText.trim();
        });

        if (_scannedText.isNotEmpty) {
          // Analyze the bill
          final billAnalysis = BillAnalyzer.analyzeBill(_scannedText);
          
          setState(() {
            _billAnalysis = billAnalysis;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully analyzed bill: ${billAnalysis.merchant} - \$${billAnalysis.amount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Details',
                textColor: Colors.white,
                onPressed: () => _showBillAnalysis(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text found in the image'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard() async {
    if (_scannedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _scannedText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _clearResults() {
    setState(() {
      _scannedText = '';
      _selectedImage = null;
      _billAnalysis = null;
    });
  }

  void _showBillAnalysis() {
    if (_billAnalysis != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionEntryScreen(
            billAnalysis: _billAnalysis!,
            imageFile: _selectedImage,
          ),
        ),
      ).then((saved) {
        if (saved == true) {
          // Transaction was saved, clear results
          _clearResults();
        }
      });
    }
  }

  Widget _buildBillAnalysisView() {
    if (_billAnalysis == null) return const SizedBox.shrink();
    
    final analysis = _billAnalysis!;
    final isExpense = analysis.transactionType == 'expense';
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant and Amount
          Card(
            color: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isExpense ? Icons.remove_circle : Icons.add_circle,
                    color: isExpense ? Colors.red : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.merchant,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${analysis.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Category and Type
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Category',
                  analysis.category,
                  Icons.category,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'Type',
                  analysis.transactionType.toUpperCase(),
                  isExpense ? Icons.remove : Icons.add,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Date
          _buildInfoCard(
            'Date',
            '${analysis.date.day}/${analysis.date.month}/${analysis.date.year}',
            Icons.calendar_today,
          ),
          
          const SizedBox(height: 12),
          
          // Confidence
          _buildConfidenceIndicator(analysis.confidence),
          
          const SizedBox(height: 12),
          
          // Items (if any)
          if (analysis.items.isNotEmpty) ...[
            const Text(
              'Extracted Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
            if (analysis.items.length > 3)
              Text(
                '... and ${analysis.items.length - 3} more items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.blue, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color confidenceColor;
    String confidenceText;
    
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceText = 'High Confidence';
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
      confidenceText = 'Medium Confidence';
    } else {
      confidenceColor = Colors.red;
      confidenceText = 'Low Confidence';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: confidenceColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  confidenceText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: confidence,
              backgroundColor: confidenceColor.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'OCR Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_billAnalysis != null)
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.white),
              onPressed: _showBillAnalysis,
              tooltip: 'View bill analysis',
            ),
          if (_scannedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: _copyToClipboard,
              tooltip: 'Copy to clipboard',
            ),
          if (_scannedText.isNotEmpty || _selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearResults,
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera/Image Preview Section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildPreviewWidget(),
              ),
            ),
          ),

          // Control Buttons Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Button
                _buildControlButton(
                  icon: Icons.camera_alt,
                  label: 'Scan',
                  onPressed: _isCameraInitialized ? _takePicture : null,
                  color: Colors.blue,
                ),
                
                // Gallery Button
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Import',
                  onPressed: _pickImageFromGallery,
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // Results Section
          if (_scannedText.isNotEmpty || _selectedImage != null)
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_fields, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Bill Analysis:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_billAnalysis != null)
                          ElevatedButton.icon(
                            onPressed: _showBillAnalysis,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Save Transaction'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _billAnalysis!.transactionType == 'expense' 
                                  ? Colors.red 
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _billAnalysis != null
                          ? _buildBillAnalysisView()
                          : _scannedText.isNotEmpty
                              ? SingleChildScrollView(
                                  child: Text(
                                    _scannedText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    'No text extracted yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
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

  Widget _buildPreviewWidget() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'Camera not available',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        if (_isScanning)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Scanning overlay
        Positioned.fill(
          child: CustomPaint(
            painter: ScanningOverlayPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null ? color : Colors.grey,
            boxShadow: [
              BoxShadow(
                color: (onPressed != null ? color : Colors.grey).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 32),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ScanningOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaSize = size.width * 0.7;

    // Draw scanning frame
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: scanAreaSize,
        height: scanAreaSize,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, paint);

    // Draw corner indicators
    final cornerLength = 20.0;
    final cornerThickness = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerThickness;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
