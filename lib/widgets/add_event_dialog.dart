/// 新增臨時項目對話框
/// 允許用戶動態添加自定義比賽項目

import 'package:flutter/material.dart';
import '../constants/event_constants.dart';
import '../models/student.dart';

/// 新增項目對話框
class AddEventDialog extends StatefulWidget {
  final Function(EventInfo) onEventAdded;

  const AddEventDialog({
    super.key,
    required this.onEventAdded,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  
  EventCategory _selectedCategory = EventCategory.track;
  List<Division> _selectedDivisions = [Division.senior];
  List<Gender> _selectedGenders = [Gender.male];
  bool _isScoring = true;
  bool _isClassRelay = false;
  int _maxParticipants = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增臨時項目'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '項目基本資訊',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // 項目編碼
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: '項目編碼',
                    hintText: '例如：TEMP01, SPECIAL100',
                    border: OutlineInputBorder(),
                    helperText: '請使用唯一的項目編碼',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入項目編碼';
                    }
                    if (value.length < 3) {
                      return '項目編碼至少需要3個字符';
                    }
                    
                    // 檢查編碼是否已存在
                    final existingEvent = EventConstants.findByCode(value.toUpperCase());
                    if (existingEvent != null) {
                      return '此項目編碼已存在';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 項目名稱
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '項目名稱',
                    hintText: '例如：臨時賽跑、特殊田賽',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入項目名稱';
                    }
                    if (value.length < 2) {
                      return '項目名稱至少需要2個字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // 項目分類
                const Text(
                  '項目分類',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EventCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '項目類別',
                    border: OutlineInputBorder(),
                  ),
                  items: EventCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // 適用組別
                const Text(
                  '適用組別',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Division.values.map((division) {
                    return FilterChip(
                      label: Text(division.displayName),
                      selected: _selectedDivisions.contains(division),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDivisions.add(division);
                          } else {
                            _selectedDivisions.remove(division);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedDivisions.isEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '請至少選擇一個組別',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                
                // 適用性別
                const Text(
                  '適用性別',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Gender.values.map((gender) {
                    return FilterChip(
                      label: Text(gender.displayName),
                      selected: _selectedGenders.contains(gender),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenders.add(gender);
                          } else {
                            _selectedGenders.remove(gender);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedGenders.isEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '請至少選擇一個性別',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                
                // 項目設定
                const Text(
                  '項目設定',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                CheckboxListTile(
                  title: const Text('計入總分'),
                  subtitle: const Text('取消勾選表示此項目為展示賽'),
                  value: _isScoring,
                  onChanged: (value) {
                    setState(() {
                      _isScoring = value ?? true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                CheckboxListTile(
                  title: const Text('班級接力賽'),
                  subtitle: const Text('勾選表示這是班級團體項目'),
                  value: _isClassRelay,
                  onChanged: (value) {
                    setState(() {
                      _isClassRelay = value ?? false;
                      if (_isClassRelay && _maxParticipants == 1) {
                        _maxParticipants = 4; // 接力賽預設4人
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                // 最大參賽人數
                TextFormField(
                  initialValue: _maxParticipants.toString(),
                  decoration: const InputDecoration(
                    labelText: '最大參賽人數',
                    border: OutlineInputBorder(),
                    helperText: '個人項目通常為1，接力賽通常為4',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入最大參賽人數';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1) {
                      return '請輸入有效的人數（至少1人）';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final number = int.tryParse(value);
                    if (number != null && number > 0) {
                      _maxParticipants = number;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _submitForm : null,
          child: const Text('新增項目'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedDivisions.isNotEmpty && _selectedGenders.isNotEmpty;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _canSubmit()) {
      final event = EventInfo(
        code: _codeController.text.toUpperCase().trim(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        divisions: _selectedDivisions,
        genders: _selectedGenders,
        isScoring: _isScoring,
        isClassRelay: _isClassRelay,
        maxParticipants: _maxParticipants,
        specialRules: _isClassRelay ? '班級團體項目' : '',
      );

      widget.onEventAdded(event);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功新增項目：${event.name} (${event.code})'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 