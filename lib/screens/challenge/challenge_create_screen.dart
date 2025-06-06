import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/challenge/challenge_service.dart';

class CreateChallengeScreen extends StatefulWidget {
  @override
  _CreateChallengeScreenState createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _cautionsController = TextEditingController();

  int _selectedWeeks = 1;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // 새로 추가된 필드들
  String _selectedCategory = 'lifestyle';
  String _selectedFrequencyType = 'daily';
  int _selectedFrequencyInterval = 1;
  int _maxParticipants = 10; // 새로 추가 (기본값 10명)

  final List<Map<String, String>> _categories = [
    {'value': 'health', 'label': '건강'},
    {'value': 'exercise', 'label': '운동'},
    {'value': 'study', 'label': '학습'},
    {'value': 'hobby', 'label': '취미'},
    {'value': 'lifestyle', 'label': '라이프스타일'},
    {'value': 'social', 'label': '소셜'},
    {'value': 'other', 'label': '기타'},
  ];

  final List<Map<String, String>> _frequencyTypes = [
    {'value': 'daily', 'label': '매일'},
    {'value': 'weekly', 'label': '매주'},
    {'value': 'monthly', 'label': '매월'},
  ];

  // 주기 유형에 따른 범위와 단위 반환
  Map<String, dynamic> _getFrequencyConfig() {
    switch (_selectedFrequencyType) {
      case 'daily':
        return {
          'min': 1.0,
          'max': 10.0,
          'divisions': 9,
          'unit': '번/일',
          'description': '하루에 몇 번 수행할지 선택하세요',
        };
      case 'weekly':
        return {
          'min': 1.0,
          'max': 7.0,
          'divisions': 6,
          'unit': '번/주',
          'description': '일주일에 몇 번 수행할지 선택하세요',
        };
      case 'monthly':
        return {
          'min': 1.0,
          'max': 30.0,
          'divisions': 29,
          'unit': '번/월',
          'description': '한 달에 몇 번 수행할지 선택하세요',
        };
      default:
        return {
          'min': 1.0,
          'max': 10.0,
          'divisions': 9,
          'unit': '번',
          'description': '',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final frequencyConfig = _getFrequencyConfig();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '새 챌린지 만들기',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 챌린지 제목
              _buildInputSection(
                label: '챌린지 제목 *',
                child: TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('챌린지 제목을 입력하세요'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '챌린지 제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),

              // 챌린지 카테고리 추가
              _buildInputSection(
                label: '카테고리 *',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      iconEnabledColor: Colors.grey[600],
                      iconSize: 28,
                      dropdownColor: Colors.white,
                      elevation: 8, // 그림자 효과
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      items:
                          _categories.map<DropdownMenuItem<String>>((
                            Map<String, String> category,
                          ) {
                            return DropdownMenuItem<String>(
                              value: category['value']!,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  category['label']!,
                                  style: TextStyle(
                                    color:
                                        _selectedCategory == category['value']
                                            ? Colors
                                                .black // 선택된 아이템은 진한 색
                                            : Colors.black87, // 나머지는 약간 연한 색
                                    fontSize: 16,
                                    fontWeight:
                                        _selectedCategory == category['value']
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),

              // 챌린지 설명
              _buildInputSection(
                label: '챌린지 설명 *',
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration('챌린지에 대한 자세한 설명을 입력하세요'),
                  maxLines: 4,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '챌린지 설명을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),

              // 챌린지 이미지
              _buildInputSection(
                label: '챌린지 이미지',
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child:
                      _selectedImage != null
                          ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : InkWell(
                            onTap: _showImagePickerDialog,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '이미지 추가하기',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '(선택사항)',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),

              // 챌린지 주기 수정
              _buildInputSection(
                label: '챌린지 주기 *',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 주기 유형 선택
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '주기 유형:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFrequencyType,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedFrequencyType = newValue!;
                                    // 주기 유형이 변경되면 간격을 기본값으로 리셋
                                    _selectedFrequencyInterval = 1;
                                  });
                                },
                                items:
                                    _frequencyTypes
                                        .map<DropdownMenuItem<String>>((
                                          Map<String, String> type,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: type['value']!,
                                            child: Text(type['label']!),
                                          );
                                        })
                                        .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // 설명 텍스트
                      Text(
                        frequencyConfig['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),

                      SizedBox(height: 12),

                      // 주기 간격 슬라이더
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '빈도:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Slider(
                                  value: _selectedFrequencyInterval.toDouble(),
                                  min: frequencyConfig['min'],
                                  max: frequencyConfig['max'],
                                  divisions: frequencyConfig['divisions'],
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFrequencyInterval =
                                          value.round();
                                    });
                                  },
                                ),
                                Text(
                                  '$_selectedFrequencyInterval${frequencyConfig['unit']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 예시 텍스트
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getExampleText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 최대 참가자 수
              _buildInputSection(
                label: '최대 참가자 수 *',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '참가자 수:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Slider(
                                  value: _maxParticipants.toDouble(),
                                  min: 5.0,
                                  max: 50.0,
                                  divisions: 9, // (50-5)/5 = 9개 구간
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      _maxParticipants =
                                          (value / 5).round() * 5; // 5명 단위로 조정
                                    });
                                  },
                                ),
                                Text(
                                  '$_maxParticipants명',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '최대 $_maxParticipants명까지 참가할 수 있습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 챌린지 규칙
              _buildInputSection(
                label: '챌린지 규칙 *',
                child: TextFormField(
                  controller: _rulesController,
                  decoration: _inputDecoration('챌린지 규칙을 입력하세요'),
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '챌린지 규칙을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),

              // 주의사항 (별도 컨트롤러 사용)
              _buildInputSection(
                label: '주의사항 *',
                child: TextFormField(
                  controller: _cautionsController,
                  decoration: _inputDecoration('주의사항을 입력하세요'),
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '주의사항을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 30),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '챌린지 생성',
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
    );
  }

  Widget _buildInputSection({required String label, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.orange[800], height: 1.4),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('취소'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _uploadedImageUrl; // 업로드된 이미지 URL

  // 이미지 선택 및 업로드
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')));
    }
  }

  void _createChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('챌린지 생성 중...'),
              ],
            ),
          ),
    );

    try {
      final challengeService = ChallengeService();

      // 1. 먼저 챌린지를 생성 (이미지 없이)
      final result = await challengeService.createChallenge(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        rules: _rulesController.text,
        cautions: _cautionsController.text,
        maxParticipants: _maxParticipants,
        frequencyType: _selectedFrequencyType,
        frequencyInterval: _selectedFrequencyInterval,
      );

      if (!result['success']) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showErrorDialog(result['message'] ?? '챌린지 생성에 실패했습니다.');
        return;
      }

      final challengeId = result['data']['data']['challenge']['_id'];

      // 2. 이미지가 있다면 업로드하고 챌린지에 연결
      if (_selectedImage != null) {
        // 로딩 메시지 업데이트
        Navigator.pop(context); // 기존 다이얼로그 닫기
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('이미지 업로드 중...'),
                  ],
                ),
              ),
        );

        final imageResult = await challengeService.updateChallengeImage(
          challengeId,
          _selectedImage!,
        );

        Navigator.pop(context); // 이미지 업로드 다이얼로그 닫기

        if (!imageResult['success']) {
          // 이미지 업로드 실패해도 챌린지는 이미 생성됨
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('챌린지는 생성되었지만 이미지 업로드에 실패했습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }

      // 성공 메시지
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('성공'),
              content: Text('챌린지가 생성되었습니다!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // 이전 화면으로 돌아가기
                  },
                  child: Text('확인'),
                ),
              ],
            ),
      );
    } catch (error) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showErrorDialog('오류가 발생했습니다: $error');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('오류'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  // 예시 텍스트 생성
  String _getExampleText() {
    switch (_selectedFrequencyType) {
      case 'daily':
        return '예: 하루에 $_selectedFrequencyInterval번 운동하기';
      case 'weekly':
        return '예: 일주일에 $_selectedFrequencyInterval번 독서하기';
      case 'monthly':
        return '예: 한 달에 $_selectedFrequencyInterval번 등산하기';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _cautionsController.dispose(); // 새로 추가된 컨트롤러 해제
    super.dispose();
  }
}
