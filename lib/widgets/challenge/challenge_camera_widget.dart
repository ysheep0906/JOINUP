import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChallengeCameraWidget extends StatefulWidget {
  final Function(File) onPhotoTaken;

  const ChallengeCameraWidget({super.key, required this.onPhotoTaken});

  @override
  State<ChallengeCameraWidget> createState() => _ChallengeCameraWidgetState();
}

class _ChallengeCameraWidgetState extends State<ChallengeCameraWidget> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 카메라 권한 확인
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카메라 권한이 필요합니다.')));
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0], // 첫 번째 카메라 (후면 카메라)
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카메라를 초기화할 수 없습니다.')));
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();

      // 현재 시간으로 타임스탬프 생성
      final now = DateTime.now();
      final timestamp =
          '${now.year}년 ${now.month}월 ${now.day}일 ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // 이미지에 타임스탬프 추가
      final File processedImage = await _addTimestampToImage(
        File(photo.path),
        timestamp,
      );

      widget.onPhotoTaken(processedImage);
      Navigator.of(context).pop();
    } catch (e) {
      print('사진 촬영 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진을 촬영할 수 없습니다.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> _addTimestampToImage(File imageFile, String timestamp) async {
    try {
      // 이미지 파일을 바이트로 읽기
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 이미지 디코딩
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('이미지를 디코딩할 수 없습니다.');
      }

      // 이미지 크기 조정 (너무 크지 않게)
      if (originalImage.width > 1080) {
        originalImage = img.copyResize(originalImage, width: 1080);
      }

      // 타임스탬프를 이미지 중앙에 추가
      final int fontSize =
          (originalImage.width * 0.06).round(); // 이미지 크기에 비례한 폰트 크기
      final img.BitmapFont font = img.arial48; // 기본 폰트 사용

      // 텍스트 배경을 위한 반투명 검정 사각형 그리기
      final int textWidth = timestamp.length * (fontSize ~/ 2);
      final int textHeight = fontSize + 20;
      final int x = (originalImage.width - textWidth) ~/ 2;
      final int y = (originalImage.height - textHeight) ~/ 2;

      // 반투명 배경 사각형
      img.fillRect(
        originalImage,
        x1: x - 10,
        y1: y - 10,
        x2: x + textWidth + 10,
        y2: y + textHeight + 10,
        color: img.ColorRgba8(0, 0, 0, 128), // 반투명 검정
      );

      // 텍스트 추가 (흰색)
      img.drawString(
        originalImage,
        timestamp,
        font: font,
        x: x,
        y: y,
        color: img.ColorRgba8(255, 255, 255, 255), // 흰색
      );

      // 처리된 이미지를 임시 파일로 저장
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/challenge_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File tempFile = File(tempPath);

      // JPEG로 인코딩하여 저장
      final List<int> encodedImage = img.encodeJpg(originalImage, quality: 85);
      await tempFile.writeAsBytes(encodedImage);

      // 원본 파일 삭제
      await imageFile.delete();

      return tempFile;
    } catch (e) {
      print('이미지 처리 실패: $e');
      // 실패 시 원본 이미지 반환
      return imageFile;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('챌린지 인증 사진', style: TextStyle(color: Colors.white)),
      ),
      body:
          _isInitialized
              ? Stack(
                children: [
                  // 카메라 프리뷰
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),

                  // 중앙에 시간 오버레이 (미리보기용)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCurrentTimeString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 하단 컨트롤
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : GestureDetector(
                                  onTap: _takePicture,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
    );
  }

  String _getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.year}년 ${now.month}월 ${now.day}일 ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
