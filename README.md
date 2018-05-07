# Playing-Cards-Recognition-Using-OpenCV-in-Swift

#Overview
This code recognize the playing cards in an image
The main function take a UIImage as an input, and return an NSString that contain the result

#Originaly: 
This code was designed to process imges from a video feed. 

#limitations:
This card recognition process works well in a lot of cases but has some limitations:
- It  requires that all edges be in the picture. 
- It is programed to detect the standard type of playing cards. 
- It will not be able to recognize a card that does not show suit and rank in their normal place (top left corner)

#To communicate with OpenCv from swift 
Three files are needed
- OpenCVWrapper.h
  the interface to the Objective-C code.
  EX: + (NSString *)imagePreprocessing:(UIImage *)source{}
- OpenCVWrapper.mm
  Where openCv is imported and the implementation is. 
  EX: implementation for: + (NSString *)imagePreprocessing:(UIImage *)source{......}
- Bridging header 
  The bridging header tells Swift code about the Objective-C code that is available. 

#Then: from Swift call: OpenCVWrapper.imagePreprocessing(image);
