library ingest;

// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:math';

import 'package:flutter/material.dart';

typedef DataFetcherBuilder<T> = Widget Function(BuildContext context,
    DataField<T> field, ValueChanged<T> onChanged, VoidCallback onExit);

class DataFetchers {
  static final DataFetcherBuilder<dynamic> textFieldString =
      (context, field, onChanged, onExit) => TextField(
            onChanged: onChanged,
            autofocus: true,
            obscureText: field.dataType.isObscured(),
            minLines: field.dataType.longText() ? 3 : 1,
            onSubmitted: (e) {
              onChanged(e);
              onExit();
            },
            controller: TextEditingController(text: field.getDefaultValue()),
            maxLength: field.getMaxLength().toInt(),
            decoration: InputDecoration(
              labelText: field.getName(),
              hintText: field.getHelp(),
            ),
          );
}

abstract class DataType<T> {
  static final DataType<String> stringField = StringDataType();
  static final DataType<String> obscuredStringField = ObscuredStringDataType();
  static final DataType<String> longStringField = LongStringDataType();
  static final DataType<int> intField = IntDataType();
  static final DataType<double> doubleField = DoubleDataType();

  bool isObscured() => false;

  bool longText() => false;

  List<DataFetcherBuilder<dynamic>> getSupportedFetchers();

  T getDefaultValue();

  String formatToString(T value);

  T formatFromString(String value);

  double defaultMinLength();

  double defaultMaxLength();
}

class StringDataType extends DataType<String> {
  @override
  List<DataFetcherBuilder<dynamic>> getSupportedFetchers() => [
        DataFetchers.textFieldString,
      ];

  @override
  String getDefaultValue() => "";

  @override
  String formatFromString(String value) => value;

  @override
  String formatToString(String value) => value;

  @override
  double defaultMinLength() => 0;

  @override
  double defaultMaxLength() => 8192;
}

class ObscuredStringDataType extends StringDataType {
  @override
  bool isObscured() => true;
}

class LongStringDataType extends StringDataType {
  @override
  bool longText() => true;
}

class IntDataType extends DataType<int> {
  @override
  List<DataFetcherBuilder<dynamic>> getSupportedFetchers() => [];

  @override
  int getDefaultValue() => 0;

  @override
  int formatFromString(String value) => int.parse(value);

  @override
  String formatToString(int value) => value.toString();

  @override
  double defaultMinLength() => 0;

  @override
  double defaultMaxLength() => 100;
}

class DoubleDataType extends DataType<double> {
  @override
  List<DataFetcherBuilder<dynamic>> getSupportedFetchers() => [];

  @override
  double getDefaultValue() => 0;

  @override
  double formatFromString(String value) => double.parse(value);

  @override
  String formatToString(double value) => value.toString();

  @override
  double defaultMinLength() => 0;

  @override
  double defaultMaxLength() => 100;
}

class BoolDataType extends DataType<bool> {
  @override
  List<DataFetcherBuilder<dynamic>> getSupportedFetchers() => [];

  @override
  bool getDefaultValue() => false;

  @override
  bool formatFromString(String value) => value == "true";

  @override
  String formatToString(bool value) => value.toString();

  @override
  double defaultMinLength() => 0;

  @override
  double defaultMaxLength() => 5;
}

class DataField<T> {
  String? name;
  String? help;
  DataType<T> dataType;
  T? defaultValue;
  bool? required;
  double? minLength;
  double? maxLength;

  DataField(
      {this.name,
      this.help,
      required this.dataType,
      this.defaultValue,
      this.required,
      this.minLength,
      this.maxLength});

  String getName() => name ?? "Field";

  DataType<T> getDataType() => dataType;

  T getDefaultValue() => defaultValue ?? dataType.formatFromString("");

  String getHelp() => help ?? "";

  bool isRequired() => required ?? true;

  double getMinLength() => minLength ?? dataType.defaultMinLength();

  double getMaxLength() => maxLength ?? dataType.defaultMaxLength();
}

Future<T> ingest<T>(BuildContext context, DataField<T> field) {
  T selected = field.getDefaultValue();
  return showDialog(
      context: context,
      builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field.getDataType().getSupportedFetchers().first(
                      context,
                      field,
                      (value) => selected = value,
                      () => Navigator.pop(context, selected)),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () => Navigator.pop(context, selected),
                          child: const Text("Done")),
                    ],
                  )
                ],
              ),
            ),
          )).then((value) => value ?? selected);
}

Future<List<dynamic>> ingestMultiple(
    BuildContext context, List<DataField<dynamic>> fields) {
  List<dynamic> selected = List.generate(fields.length, (index) => null);
  int mindex = 0;
  PageController controller = PageController(viewportFraction: 1);

  return showDialog(
      context: context,
      builder: (context) => Dialog(
            child: ExpandablePageView(
              controller: controller,
              children: [
                ...fields.map((e) {
                  int index = mindex;
                  mindex++;
                  Widget w = Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        e.getDataType().getSupportedFetchers().first(
                            context, e, (value) => selected[index] = value, () {
                          if (index < fields.length - 1) {
                            controller.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCirc);
                          } else {
                            Navigator.pop(context, selected);
                          }
                        }),
                        Row(
                          children: [
                            const Spacer(),
                            TextButton(
                                onPressed: () {
                                  if (index == 0) {
                                    Navigator.pop(context, null);
                                  } else {
                                    controller.previousPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeInOutCirc);
                                  }
                                },
                                child: Text(index == 0 ? "Cancel" : "Back")),
                            TextButton(
                                onPressed: () {
                                  if (index < fields.length - 1) {
                                    controller.nextPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeInOutCirc);
                                  } else {
                                    Navigator.pop(context, selected);
                                  }
                                },
                                child: Text(index == fields.length - 1
                                    ? "Done"
                                    : "Next")),
                          ],
                        )
                      ],
                    ),
                  );
                  return w;
                })
              ],
            ),
          )).then((value) => value ?? selected);
}

class ExpandablePageView extends StatefulWidget {
  final PageController controller;
  final List<Widget> children;

  const ExpandablePageView({
    Key? key,
    required this.controller,
    required this.children,
  }) : super(key: key);

  @override
  _ExpandablePageViewState createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView>
    with TickerProviderStateMixin {
  late List<double> _heights;
  int _currentPage = 0;

  double get _currentHeight => _heights[_currentPage];

  @override
  void initState() {
    _heights = widget.children.map((e) => 0.0).toList();
    super.initState();
    widget.controller.addListener(() {
      final _newPage = (widget.controller.page ?? 0.0).round();
      if (_currentPage != _newPage) {
        setState(() => _currentPage = _newPage);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: Curves.easeInOutCirc,
      duration: const Duration(milliseconds: 333),
      tween: Tween<double>(begin: _heights[0], end: _currentHeight),
      builder: (context, value, child) => SizedBox(height: value, child: child),
      child: PageView(
        controller: widget.controller,
        children: _sizeReportingChildren
            .asMap() //
            .map((index, child) => MapEntry(index, child))
            .values
            .toList(),
      ),
    );
  }

  List<Widget> get _sizeReportingChildren => widget.children
      .asMap() //
      .map(
        (index, child) => MapEntry(
          index,
          OverflowBox(
            //needed, so that parent won't impose its constraints on the children, thus skewing the measurement results.
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: SizeReportingWidget(
              onSizeChange: (size) => setState(() => _heights[index] =
                  min(MediaQuery.of(context).size.height, size.height)),
              child: Align(child: child),
            ),
          ),
        ),
      )
      .values
      .toList();
}

class SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChange;

  const SizeReportingWidget({
    Key? key,
    required this.child,
    required this.onSizeChange,
  }) : super(key: key);

  @override
  _SizeReportingWidgetState createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<SizeReportingWidget> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 16), () => _notifySize());
    Future.delayed(const Duration(milliseconds: 100), () => _notifySize());
    Future.delayed(const Duration(milliseconds: 250), () => _notifySize());
    Future.delayed(const Duration(milliseconds: 750), () => _notifySize());
    return widget.child;
  }

  void _notifySize() {
    if (!this.mounted) {
      return;
    }
    final size = context.size;
    if (_oldSize != size) {
      _oldSize = size;
      widget.onSizeChange(size!);
    }
  }
}
