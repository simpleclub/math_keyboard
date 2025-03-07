import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_parser/math_parser.dart';

class EditableMixedTextField extends StatefulWidget {
  /// Creates an instance of [EditableMixedTextField].
  ///
  /// This widget allows users to input and edit both text and mathematical expressions.
  EditableMixedTextField({super.key});

  @override
  EditableMixedTextFieldState createState() => EditableMixedTextFieldState();
}

class EditableMixedTextFieldState extends State<EditableMixedTextField> {
  /// A list to store text and mathematical expressions.
  List<Map<String, dynamic>> textElements = [];

  /// Controller for managing text input.
  TextEditingController textController = TextEditingController();
  MathFieldEditingController mathController = MathFieldEditingController();
  FocusNode textFocusNode = FocusNode();
  FocusNode mathFocusNode = FocusNode();
  int? editingIndex; // 현재 수정 중인 인덱스
  bool isMathMode = false; // 현재 입력 모드 (수식/일반 텍스트)
  bool isEditing = false;
  Color editingColor = Colors.green;
  String? latexExpression;


  // 텍스트 또는 수식 추가/수정
  void _addOrEditElement() {
      if (editingIndex != null) {
        // 수정 모드
        if (isMathMode) {
          textElements[editingIndex!] = {
            'type': 'math',
            'value': mathController.currentEditingValue(),
          };
          mathController.clear();
        } else {
          textElements[editingIndex!] = {
            'type': 'text',
            'value': textController.text,
          };
          textController.clear();
      // textFocusNode.unfocus();

        }
        editingIndex = null; // 수정 완료 후 초기화
      } else {
        // 새 요소 추가 모드
        if (isMathMode) {
          textElements.add({
            'type': 'math',
            'value': mathController.currentEditingValue(),
          });
        } else {
          textElements.add({
            'type': 'text',
            'value': textController.text,
          });
        }
      }
      isEditing = false;
    setState(() {
    });
  }

  // 요소를 수정할 때 실행
  void _editElement(int index) {
    isEditing = true;
      editingIndex = index;
      isMathMode = textElements[index]['type'] == 'math';
      if (isMathMode) {
        
        mathController.clear();
        print(textElements[index]['value']);
        // 수식을 MathField에 설정
        try {
          // final Expression before = TeXParser(textElements[index]['value']).parse();
          // mathController.updateValue(before);
        mathController.updateValue(TeXParser(textElements[index]['value']).parse());
        // mathController.updateValue(Parser().parse(textElements[index]['value']));
        } catch (e) {
          print(e.toString());
        }
        mathFocusNode.requestFocus();
      } else {
        // 일반 텍스트를 TextField에 설정
        textController.text = textElements[index]['value'];
        textFocusNode.requestFocus();
      }
      print('mathFocusNode.hasFocus: ${mathFocusNode.hasFocus}');
      print('textFocusNode.hasFocus: ${textFocusNode.hasFocus}');
    setState(() {
    });
  }

  String convertApiLatexToMathKeyboard(String apiLatex) {
    // '$' 문자 제거
    print(TeXParser(apiLatex.replaceAll('\$', '')).parse().toString());
    return TeXParser(apiLatex.replaceAll('\$', '')).parse().toString();
    // return apiLatex.replaceAll('\$', '');
  }

  String preProcessEquation(String equation) {
  // '=' 기호를 기준으로 방정식을 분리
  List<String> parts = equation.split('=');
String rightSide = '';

  if (equation.contains('=') && parts.length != 2) {
    throw FormatException('Invalid equation format');
  }

  if (parts.length > 1) {
  // 우변만 LaTeX 형식으로 변환
    rightSide = parts[1].trim();

    rightSide = rightSide.replaceAllMapped(RegExp(r'(\d)([a-zA-Z])'), (match) {
    return '${match.group(1)}${match.group(2)}';
  });

  return '${parts[0].trim()}=$rightSide';
  } else {
    return equation;
  }
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
        String convertedLatex = preProcessEquation(part);
        textElements.add({
          'type': 'math',
          'value': convertedLatex,
        });
      } else {
        // 짝수 인덱스는 일반 텍스트
        textElements.add({
          'type': 'text',
          'value': part.replaceAll('<br>', '').replaceAll('\n', ' '),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          mathFocusNode.unfocus();
          textFocusNode.unfocus();
          isEditing = false;
          setState(() {});
        },
        child: Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 500,
                        height: 400,
                        child: Image.asset('assets/images/ocr_test3.png'), // 이미지 경로 설정
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          // apiLatex 문자열을 textElements에 변환하여 추가
                          String apiLatex =
                              "3은 분수 \$\\frac{3}{1}\$ - 0.2<br>\n포함할 수 있는 \$\\frac{6}{2}\$ 으로 표현도니";
                              // "30.1% 12시간 300g → 3.6% \$\\times \\frac{3}{100}\$ = 90g<br><br>\n10% 12시간 x g → 0.1x g<br><br>\n\$\\frac{90 + 0.1x}{300 + x \\leq 0.18\$<br><br>\n\$90 + 0.1x \\leq 54 + 0.18x\$<br><br>\n36 \$\\\leq 0.08x\$<br><br>\n\$\\frac{3600}{8} \\leq x\$<br>\n\$450 \\leq x\$";
                              // "이차함수 \$y = x^2 - 3x + 2\$의<br>\n해를 구하시오.<br>\n\$x = 2\$ 또는 \$x = 1\$";
                          parseAndAddApiLatex(apiLatex);
                          setState(() {});
                        },
                        child: Text('변환하기', style: TextStyle(color: Colors.white, fontSize: 20)),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          // convertToLatex();
                        },
                        child: Text('LaTeX변환', style: TextStyle(color: Colors.white, fontSize: 20)),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(),
              Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (isEditing)
                      SingleChildScrollView(
                        child: 
                      isMathMode
                          ? MathField(
                            textAlign: TextAlign.start,
                            focusNode: mathFocusNode,
                            autofocus: true,
                              controller: mathController,
                              variables: const ['a', 'b', 'c', 'x', 'y', 'z', '='],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '수식을 입력하세요',
                                suffix: editOrCancelButton(),
                                
                              ),
                              mathField: MathField(
                                autofocus: true,
                                textAlign: TextAlign.center,
                                controller: mathController,
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      mathController.clear();
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(color: Color.fromRGBO(235, 235, 235, 1)),
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.close)),
                                  ),
                                  border: InputBorder.none,
                                ),
                                // variables: const ['a', 'b', 'c', 'x', 'y', 'z', '='],
                              ),
                              // onChanged: (value) {
                              //   setState(() {});
                              // },
                            )
                          : TextField(
                            focusNode: textFocusNode,
                            autofocus: true,
                              controller: textController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '일반 텍스트를 입력하세요',
                                suffix: FittedBox(
                                  child: Row(
                                    children: [
                                      ElevatedButton(
                                                          onPressed: _addOrEditElement,
                                                          child: Text('수정'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            textFocusNode.unfocus();
                                                            isEditing = false;
                                                            editingIndex = null;
                                                            setState(() {});
                                                          },
                                                          child: Text('취소'),
                                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              
                            ),
                      ),
                      SizedBox(height: 10),
                      
                      
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
                                onTap: () {        
                                  _editElement(index);
                                },
                                child: element['type'] == 'math'
                                    ? Container(
                                      color: Colors.transparent,
                                        margin: EdgeInsets.symmetric(horizontal: 2),
                                        child: Baseline(
                                          baseline: 16,
                    baselineType: TextBaseline.alphabetic,
                                          child: Math.tex(
                                            element['value'] ?? '', // 수식 값 설정
                                            textStyle: TextStyle(fontSize: 18, color: editingIndex == index ? editingColor : Colors.black),
                                            options: MathOptions(fontSize: 18, color: editingIndex == index ? editingColor : Colors.black),
                                          ),
                                        ),
                                      )
                                    : Container(
                                      color: Colors.transparent,
                                        margin: EdgeInsets.symmetric(horizontal: 2),
                                        child: Text(
                                          element['value'],
                                          style: TextStyle(fontSize: 18, color: editingIndex == index ? editingColor : Colors.black),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget editOrCancelButton() {
    return FittedBox(
      child: Row(children: [ElevatedButton(onPressed: _addOrEditElement, child: Text('수정')), ElevatedButton(onPressed: () {
        // if (isMathMode) {
        //   mathController.clear();
        // mathFocusNode.unfocus();
        // } else {
        //   textController.clear();
        //   textFocusNode.unfocus();
        // }
        isEditing = false;
        editingIndex = null;
        setState(() {});
      }, child: Text('취소'))],),);
  }
}
