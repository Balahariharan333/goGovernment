import 'package:image_picker/image_picker.dart';

abstract class ComplaintEvent {}

class SelectComplaintCategoryEvent extends ComplaintEvent {
  final String category;
  SelectComplaintCategoryEvent(this.category);
}

class PickComplaintImageEvent extends ComplaintEvent {
  final XFile image;
  PickComplaintImageEvent(this.image);
}

class SubmitComplaintEvent extends ComplaintEvent {
  final String description;
  SubmitComplaintEvent(this.description);
}

class ClearComplaintEvent extends ComplaintEvent {}
