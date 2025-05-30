import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:record3/screens/recording_screen.dart';
import 'package:record3/screens/upload_info.dart';
import 'package:record3/vos/upload_vo.dart';

class InputScreen extends StatefulWidget {
  final String userType;

  InputScreen({required this.userType});

  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  XFile? _selectedFile;
  String _uploadStatus = '파일을 선택하세요';

  List<Map<String, String>> attendees = [];
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _controller5 = TextEditingController();
  DateTime? _selectedDateTime;
  final TextEditingController _dateTimeController = TextEditingController();
  Key _roleFieldKey = UniqueKey();

  Future<void> _pickFile() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'audio', extensions: ['mp3', 'wav', 'aac']),
        ],
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _uploadStatus = '파일 선택 완료: ${file.name}';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '파일 선택 오류: $e';
      });
    }
  }

  void _navigateToUploadScreen(BuildContext context) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} 24',
    );

    if (_selectedFile == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("파일 없음"),
            content: const Text("파일을 먼저 선택해주세요."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
    } else if (attendees.isEmpty) {
      // 참석자 없을 때 처리 (생략)
    } else {
      final uploadVo = UploadVO(
        subj: _controller1.text,
        infoN: attendees,
        loc: _controller5.text,
        df: _dateTimeController.text,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadScreen(
            uploadVo: uploadVo,
            recordFile: _selectedFile,
          ),
        ),
      );
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Color(0xFFD9D9D9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '입력한 회의 정보를 확인해주세요.\n이후에는 정보를 수정할 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('돌아가기', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // 팝업 닫기
                          // 분석하기(업로드) 로직 실행
                          final uploadVo = UploadVO(
                            subj: _controller1.text,
                            infoN: attendees,
                            loc: _controller5.text,
                            df: _dateTimeController.text,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadScreen(
                                uploadVo: uploadVo,
                                recordFile: _selectedFile,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1F72DE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('분석하기', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _onAddAttendee() {
    if (_nameController.text.trim().isEmpty) {
      _showAlertDialog('이름을 입력하세요');
      return;
    }
    if (_roleController.text.trim().isEmpty) {
      _showAlertDialog('역할을 입력하세요');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showAlertDialog('이메일을 입력하세요');
      return;
    }
    setState(() {
      attendees.add({
        'name': _nameController.text,
        'role': _roleController.text,
        'email': _emailController.text,
      });
      _nameController.clear();
      _roleController.clear();
      _emailController.clear();
      _roleFieldKey = UniqueKey();
    });
  }

  bool _validateAllFields() {
    if (_controller1.text.trim().isEmpty) {
      _showAlertDialog('회의 주제를 입력해주세요');
      return false;
    }
    if (_dateTimeController.text.trim().isEmpty) {
      _showAlertDialog('회의 일시를 입력해주세요');
      return false;
    }
    if (_controller5.text.trim().isEmpty) {
      _showAlertDialog('회의 장소를 입력해주세요');
      return false;
    }
    if (attendees.isEmpty) {
      _showAlertDialog('참석자 정보를 입력하세요');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회의 정보 입력'),
        backgroundColor: Color.fromRGBO(237, 244, 252, 1),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Color.fromRGBO(237, 244, 252, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('회의 주제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('회의 주제를 입력해주세요', style: TextStyle(fontSize: 15, color: Colors.black45)),
              SizedBox(height: 8),
              TextField(
                controller: _controller1,
                decoration: InputDecoration(
                  hintText: '✔ 예: 신규 프로젝트 아이디어 회의',
                  filled: true,
                  fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text('회의 일시', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('회의 일시를 선택하세요', style: TextStyle(fontSize: 15, color: Colors.black45)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final selected = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      setState(() {
                        _selectedDateTime = selected;
                        // 오전/오후 포맷으로 변환
                        final hour = pickedTime.hour;
                        final minute = pickedTime.minute.toString().padLeft(2, '0');
                        final isAM = hour < 12;
                        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                        final ampm = isAM ? '오전' : '오후';
                        _dateTimeController.text =
                          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} $ampm $displayHour:$minute';
                      });
                    }
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateTimeController,
                    decoration: InputDecoration(
                      hintText: '✔ 예: 2025-05-15 오전 11:40',
                      filled: true,
                      fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text('참석자 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('참석자 이름, 메일 주소, 역할을 설정하세요.', style: TextStyle(fontSize: 15, color: Colors.black45)),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: '이름',
                            filled: true,
                            fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: RoleSelector(
                          key: _roleFieldKey,
                          userType: widget.userType,
                          onRoleSelected: (role) {
                            _roleController.text = role;
                          },
                          decoration: InputDecoration(
                            labelText: '역할',
                            hintText: '역할',
                            filled: true,
                            fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: '메일 주소',
                            filled: true,
                            fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.blue, size: 32),
                        onPressed: _onAddAttendee,
                      ),
                    ],
                  ),
                ],
              ),
              ...attendees.map((attendee) {
                int index = attendees.indexOf(attendee);
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(237, 244, 252, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text('${attendee['name']} - ${attendee['role']}'),
                    subtitle: Text(attendee['email']!),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          attendees.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 20),

              Text('회의 장소', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('회의 장소를 입력하세요', style: TextStyle(fontSize: 15, color: Colors.black45)),
              SizedBox(height: 8),
              TextField(
                controller: _controller5,
                decoration: InputDecoration(
                  hintText: '✔ 예: 3층 회의실 A',
                  filled: true,
                  fillColor: Color.fromRGBO(82, 82, 82, 0.09),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecordingScreen()),
                          );
                          if(result != null) {
                            setState(() {
                              _selectedFile = result;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text('녹음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB0B8C1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text('파일올리기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedFile != null)
                Container(
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '선택한 파일: ${_selectedFile!.name}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_validateAllFields()) return;
                    if (_selectedFile == null) {
                      _navigateToUploadScreen(context);
                    } else {
                      _showConfirmDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1F72DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '다음',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleSelector extends StatefulWidget {
  final String userType;
  final Function(String) onRoleSelected;
  final InputDecoration? decoration;
  const RoleSelector({Key? key, required this.userType, required this.onRoleSelected, this.decoration}) : super(key: key);

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  late List<String> roles;
  String? selectedRole;
  String customRole = '';
  late TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    if (widget.userType == 'student') {
      roles = [
        '팀장 / 조장',
        '발표자',
        'PPT 제작자',
        '자료조사 담당',
        '스크립트 작성자',
        '보고서 작성자',
        '리허설 진행자',
        '기타 (직접 입력)',
      ];
    } else {
      roles = [
        '기획자 (PM)',
        '프론트엔드 개발자',
        '백엔드 개발자',
        '디자이너 (UI/UX)',
        '데이터 분석가',
        '마케터',
        '인턴/보조',
        '기타 (직접 입력)',
      ];
    }
    _displayController = TextEditingController();
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  void _updateDisplayText() {
    String displayText = selectedRole == '기타 (직접 입력)'
        ? customRole
        : (selectedRole ?? '');
    _displayController.text = displayText;
  }

  void _onRoleSelected(String role) {
    setState(() {
      if (role == '기타 (직접 입력)') {
        selectedRole = role;
        customRole = '';
      } else {
        selectedRole = role;
        customRole = '';
      }
      widget.onRoleSelected(role);
      _updateDisplayText();
    });
  }

  void _showRolePicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: List<Widget>.generate(roles.length, (index) {
                        final isEtc = roles[index] == '기타 (직접 입력)';
                        return ChoiceChip(
                          label: Text(roles[index]),
                          selected: selectedRole == roles[index],
                          onSelected: (selected) {
                            setModalState(() {
                              if (isEtc) {
                                selectedRole = '기타 (직접 입력)';
                                customRole = '';
                                _onRoleSelected('기타 (직접 입력)');
                              } else {
                                selectedRole = roles[index];
                                customRole = '';
                                _onRoleSelected(selectedRole!);
                                Navigator.pop(context);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    if (selectedRole == '기타 (직접 입력)')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: '직접 입력',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              customRole = value;
                              // onChanged에서는 _onRoleSelected를 호출하지 않음
                            });
                          },
                          onSubmitted: (value) {
                            _onRoleSelected(value);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showRolePicker,
      child: AbsorbPointer(
        child: TextField(
          controller: _displayController,
          decoration: widget.decoration,
          readOnly: true,
        ),
      ),
    );
  }
}
