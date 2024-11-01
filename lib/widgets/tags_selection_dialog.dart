import 'package:flutter/material.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TagsSelectionDialog extends StatefulWidget {
  const TagsSelectionDialog({
    required this.textfieldTagsController,
    required this.allTags,
    required this.displayTags,
    Key? key,
  }) : super(key: key);

  final TextfieldTagsController textfieldTagsController;
  final List<String> allTags;
  final List<String> displayTags;

  @override
  _TagsSelectionDialogState createState() => _TagsSelectionDialogState();
}

class _TagsSelectionDialogState extends State<TagsSelectionDialog> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  List<String> filteredTags = [];
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    filteredTags = widget.allTags;
    selectedTags = List.from(widget.textfieldTagsController.getTags ?? []);
    searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    searchController.dispose();
    textController.dispose();
    // Do NOT dispose widget.textfieldTagsController since it is passed from the parent
    super.dispose();
  }

  void _filterTags() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredTags = widget.allTags
          .where((tag) => tag.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Tags"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search tags...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            TextFieldTags(
              textEditingController: textController,
              textfieldTagsController: widget.textfieldTagsController,
              textSeparators: const [','],
              letterCase: LetterCase.normal,
              validator: (tag) {
                if (widget.textfieldTagsController.getTags?.contains(tag) ?? false) {
                  return 'You already entered that';
                }
                return null;
              },
              inputFieldBuilder: (context, textFieldTagValues) {
                return TextField(
                  controller: textFieldTagValues.textEditingController,
                  focusNode: textFieldTagValues.focusNode,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Tags',
                    hintText: 'Separate each tag using (,) ',
                    errorText: textFieldTagValues.error,
                  ),
                  onChanged: textFieldTagValues.onChanged,
                  onSubmitted: textFieldTagValues.onSubmitted,
                );
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTags.length,
                itemBuilder: (context, index) {
                  final tag = filteredTags[index];
                  return CheckboxListTile(
                    title: Text(tag),
                    value: selectedTags.contains(tag),
                    onChanged: (bool? value) {
                      _toggleTagSelection(tag);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            for (var tag in selectedTags) {
              if (!(widget.textfieldTagsController.getTags?.contains(tag) ?? false)) {
                widget.textfieldTagsController.addTag(tag);
              }
            }
            widget.textfieldTagsController.onSubmitted;
            Navigator.pop(context, widget.textfieldTagsController);
          },
          child: const Text('Add Selected Tags'),
        ),
        TextButton(
          onPressed: _createNewTag,
          child: const Text("Create New Tag +"),
        ),
      ],
    );
  }

  void _toggleTagSelection(String tag) {
    setState(() {
      textController.text = "";
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
      for(var str in selectedTags) {
        textController.text = "${textController.text} $str, ";
      }
    });
  }

  void _createNewTag() async {
    final newTagController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter new tag name"),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: newTagController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Cannot be empty';
                if (widget.allTags.contains(value)) return 'Tag already exists';
                return null;
              },
              decoration: const InputDecoration(labelText: 'New Tag'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  String newTag = newTagController.text;

                  // Add to allTags
                  widget.allTags.add(newTag);

                  // Add to selectedTags
                  selectedTags.add(newTag);

                  // Update the TextfieldTagsController to reflect the new tag
                  widget.textfieldTagsController.addTag(newTag);
                  _toggleTagSelection(newTag);
                  // Update UI and close dialog
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Add New Tag'),
            ),
          ],
        );
      },
    );
  }

}
