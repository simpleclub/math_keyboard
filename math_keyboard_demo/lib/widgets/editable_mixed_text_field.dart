import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';

class EditableMixedTextField extends StatefulWidget {
  @override
  _EditableMixedTextFieldState createState() => _EditableMixedTextFieldState();
}

class _EditableMixedTextFieldState extends State<EditableMixedTextField> {
  List<Map<String, dynamic>> textElements = []; // 텍스트와 수식을 저장할 리스트
  TextEditingController textController = TextEditingController();
  MathFieldEditingController mathController = MathFieldEditingController();
  int? editingIndex; // 현재 수정 중인 인덱스
  bool isMathMode = false; // 현재 입력 모드 (수식/일반 텍스트)

  // 텍스트 또는 수식 추가/수정
  void _addOrEditElement() {
    setState(() {
      if (editingIndex != null) {
        // 수정 모드
        if (isMathMode) {
          textElements[editingIndex!] = {
            'type': 'math',
            'value': mathController.currentEditingValue(),
          };
        } else {
          textElements[editingIndex!] = {
            'type': 'text',
            'value': textController.text,
          };
        }
        editingIndex = null; // 수정 완료 후 초기화
      } else {
        // 새 요소 추가 모드
        if (isMathMode) {
          textElements.add({
            'type': 'math',
            'value': mathController.currentEditingValue().replaceAll('{', '(').replaceAll('}', ')'),
          });
        } else {
          textElements.add({
            'type': 'text',
            'value': textController.text,
          });
        }
      }
      textController.clear();
      mathController.clear();
    });
  }

  // 요소를 수정할 때 실행
  void _editElement(int index) {
    setState(() {
      editingIndex = index;
      isMathMode = textElements[index]['type'] == 'math';
      if (isMathMode) {
        // 수식을 MathField에 설정
        print(textElements[index]['value']);
        mathController.updateValue(Parser(ParserOptions(
          implicitMultiplication: true,
        )).parse(textElements[index]['value']));
      } else {
        // 일반 텍스트를 TextField에 설정
        textController.text = textElements[index]['value'];
      }
    });
  }

  String convertApiLatexToMathKeyboard(String apiLatex) {
    // '$' 문자 제거
    String cleanedLatex = apiLatex.replaceAll('\$', '');

    // '<br>' 태그 제거 (대소문자 구분 없이)
    cleanedLatex = cleanedLatex.replaceAll(RegExp(r'<br>'), '');

    // 중괄호를 괄호로 변경
    cleanedLatex = cleanedLatex.replaceAll('{', '(').replaceAll('}', ')');

    return cleanedLatex;
  }

  void parseAndAddApiLatex(String apiLatex) {
    // '$'를 기준으로 문자열을 분리
    List<String> parts = apiLatex.split('\$');

    textElements.clear();

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (part.isEmpty) continue; // 빈 문자열은 무시

      if (i % 2 == 1) {
        // 홀수 인덱스는 LaTeX 수식
        String convertedLatex = convertApiLatexToMathKeyboard(part);
        textElements.add({
          'type': 'math',
          'value': convertedLatex,
        });
      } else {
        // 짝수 인덱스는 일반 텍스트
        textElements.add({
          'type': 'text',
          'value': part,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 300,
                  height: 200,
                  child: Image.asset('assets/images/ocr_test.png'), // 이미지 경로 설정
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // apiLatex 문자열을 textElements에 변환하여 추가
                    String apiLatex =
                        "이차함수 \$(y)=(x^2)-3(x)+2\$의<br>해를 구하시오.<br>\$x = 2\$ 또는 \$x = 1\$";
                    parseAndAddApiLatex(apiLatex);
                    setState(() {});
                  },
                  child: Text('변환하기', style: TextStyle(color: Colors.white, fontSize: 20)),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                  ),
                )
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 기존 화면의 위젯들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => isMathMode = false),
                        child: Text('일반 텍스트'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => isMathMode = true),
                        child: Text('수식 입력'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  isMathMode
                      ? MathField(
                          controller: mathController,
                          variables: const ['x', 'y', 'z'],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '수식을 입력하세요',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.functions), // '=' 버튼 아이콘
                              onPressed: () {
                                // '=' 문자를 수식에 추가
                                mathController.addLeaf('=');
                              },
                            ),
                          ),
                        )
                      : TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '일반 텍스트를 입력하세요',
                          ),
                        ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addOrEditElement,
                    child: Text(editingIndex != null ? '수정 완료' : '추가'),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Wrap(
                      children: List.generate(
                        textElements.length,
                        (index) {
                          final element = textElements[index];
                          return GestureDetector(
                            onTap: () => _editElement(index),
                            child: element['type'] == 'math'
                                ? Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Math.tex(
                                      element['value'] ?? '', // 수식 값 설정
                                      textStyle: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      element['value'],
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                          );
                        },
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
