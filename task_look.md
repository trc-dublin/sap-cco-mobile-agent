# Request for Coding LLM

## Task
Create a Flutter camera feature that captures an image and gets item description using Google ML Kit.

## Requirements
1. **Camera Integration**
  - Add camera button labeled "Look"
  - Capture photo when pressed
  - Basic image quality validation

2. **ML Kit Processing**
  - Use `google_mlkit_image_labeling` to identify objects
  - Extract labels with confidence > 0.7
  - Convert labels to readable description

3. **Output**
  - Display detected item labels
  - Show confidence scores
  - Generate simple text description from labels

## Tech Stack
- Flutter
- camera package
- google_mlkit_image_labeling package

## Deliverables
1. Camera screen with "Look" button
2. ML Kit service class for image processing
3. Results screen showing item description


