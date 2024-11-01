import 'package:flutter/material.dart';

import 'package:textfield_tags/textfield_tags.dart';

class TagsAutoCompletion extends StatelessWidget {
  const TagsAutoCompletion({
    required this.textfieldTagsController,
    required this.allTags,
    required this.displayTags,
    super.key,
  });

  final TextfieldTagsController textfieldTagsController;
  final List<String>? allTags;
  final List<String> displayTags;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsViewBuilder: (context, onSelected, options) {
        return Container(
          margin: const EdgeInsets.only(right: 30),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final dynamic option = options.elementAt(index);
                    return TextButton(
                      onPressed: () {
                        onSelected(option);
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '#$option',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 74, 137, 92),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return allTags!.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selectedTag) {
        textfieldTagsController.addTag(selectedTag);
        print("TextFTC value: ${textfieldTagsController.getTags!.contains(selectedTag)}");
      },
      fieldViewBuilder: (context, ttec, tfn, onFieldSubmitted) {
        return TextFieldTags(
          textEditingController: ttec,
          focusNode: tfn,
          textfieldTagsController: textfieldTagsController,
          initialTags: displayTags,
          textSeparators: const [','],
          letterCase: LetterCase.normal,
          validator: (tag) {
            if (textfieldTagsController.getTags!.contains(tag)) {
              return 'you already entered that';
            }
            return null;
          },
          inputFieldBuilder: (context, textFieldTagValues) {
            return TextField(
              controller: textFieldTagValues.textEditingController,
              focusNode: textFieldTagValues.focusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperStyle: const TextStyle(
                  color: Color.fromARGB(255, 74, 137, 92),
                ),
                labelText: 'tags',
                hintText: 'Seperate each tag using (,)',
                errorText: textFieldTagValues.error,
                prefixIcon: textFieldTagValues.tags.isNotEmpty
                    ? SingleChildScrollView(
                        controller: textFieldTagValues.tagScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: List.generate(
                                textFieldTagValues.tags.length,
                                (index) => Container(
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color: Color.fromARGB(255, 74, 137, 92),
                                      ),
                                      margin:
                                          const EdgeInsets.only(right: 10.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            child: Text(
                                              '#${textFieldTagValues.tags.elementAt(index)}',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            onTap: () {
                                              //print("$tag selected");
                                            },
                                          ),
                                          const SizedBox(width: 4.0),
                                          InkWell(
                                            child: const Icon(
                                              Icons.cancel,
                                              size: 14.0,
                                              color: Color.fromARGB(
                                                  255, 233, 233, 233),
                                            ),
                                            onTap: () {
                                              textFieldTagValues.onTagDelete(
                                                  textFieldTagValues.tags
                                                      .elementAt(index));
                                            },
                                          )
                                        ],
                                      ),
                                    ))),
                      )
                    : null,
              ),
              onChanged: textFieldTagValues.onChanged,
              onSubmitted: textFieldTagValues.onSubmitted,
            );
          },
        );
      },
    );
  }
}
