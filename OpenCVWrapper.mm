//
//  OpenCVWrapper.m
//  tryOpenCV
//
//  Created by Hattan Omrani on 1/24/18.
//  Copyright © 2018 Hattan Omrani. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>



using namespace std;
using namespace cv;

@implementation OpenCVWrapper

+ (NSString *)imagePreprocessing:(UIImage *)source{
    // From UIImage to Mat
    Mat matSource;
    UIImageToMat(source, matSource);
    
    // **************** Image  preprocessing ********************* //
    Mat preprocessingImage;
    //TO: gray
    cv::cvtColor(matSource, preprocessingImage, CV_BGR2GRAY);
    // BLUR
    GaussianBlur(preprocessingImage,preprocessingImage,cv::Size(21,21),0);
    // THRESHOLD: using THRESH_OTSU
    threshold(preprocessingImage, preprocessingImage, 0, 255,THRESH_BINARY+THRESH_OTSU);


    // **************** Cards Extraction: By finding the contours ********************** //
    vector<vector<cv::Point> > contours;
    vector<Vec4i> hierarchy;
    //findContours: a  contour is a vector of points that represent a shape or something.
    findContours( preprocessingImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE,cv::Point(0,0));
    //preprocessingImage.release();

    // Look for and keep index of cards cantors
    double CARD_MAX_AREA = 10000000; // 9,000,000
    double CARD_MIN_AREA = 40000;  //50000
    vector<int> cards_index;
    for( int i = 0; i< contours.size(); i++ )
    {

        // GET: contour area
        double area0 = contourArea(contours[i]);
        // CHECK: if within required area size
        if(area0 > CARD_MIN_AREA && area0 < CARD_MAX_AREA){
            // CHECK: if does not have parent
            if (hierarchy[i][3] == -1){
                // CHECK: if it has foour corners.
                vector<cv::Point2f> approxArray_1;
                // Get area and use it to approximate corner points of the contour
                double peri = arcLength(contours[i],true);
                approxPolyDP(contours[i],approxArray_1,0.05*peri,true);
                // Ignore contours with != 4 corners.
                if(approxArray_1.size() == 4){
                    cards_index.push_back(i);
                }
            }
        }
    }
    //cout << cards_index.size() << " <<#Cards in this pic\n";
    if(cards_index.size() == 0){
        return @"NA";
    }


    NSString *result = @"";
    //NSString *split = @"/";
    // loop through cards container and identfy each one of them
    for (int i=0; i< cards_index.size(); i++){
        NSString *tempString = processACard(matSource,contours, cards_index[i]);
        result = [result stringByAppendingString:tempString];
        //result = [result stringByAppendingString: split];
    }
    return result;
}// end of imagePreprocessing Main Func


///////////////////////////////////////////////////////////////////////////////////////
/////////////////////////    Mark:- Helper Functions        ///////////////////////////

    //  Func to Process each Card
    NSString* processACard(Mat sourceImage,vector<vector<cv::Point>> contours, int index){
        // **************** Card transofrmation ********************** //
        // do Transformation using MinAreaRect()
        cv::RotatedRect rotated_Rect = minAreaRect(contours[index]); // use less than 13
        Point2f vertices[4];
        rotated_Rect.points(vertices);
        
        vector<cv::Point2f> verticesVec;
        verticesVec.push_back(vertices[0]);
        verticesVec.push_back(vertices[1]);
        verticesVec.push_back(vertices[2]);
        verticesVec.push_back(vertices[3]);
        
        // use boundingRect to get information about the contour and determain oriantation.
        cv::Rect myRect = boundingRect(contours[index]);
        
        // Creat Destination vector basid on card oriantation.
        int maxHeight = 300;
        int maxWidth = 200;
        vector<cv::Point2f> dstArray;
        
        // card is vertically orianted.
        if(myRect.width <= 0.8*myRect.height){
            bool tr = false;
            double dBetweenP0_P1 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[1]);
            double dBetweenP0_P3 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[3]);
            if(dBetweenP0_P3 > dBetweenP0_P1){
                tr = true;
            }
            
            if(tr){
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
                dstArray.push_back(Point2f(0,maxHeight-1));
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
                
            }else{
                dstArray.push_back(Point2f(0,maxHeight-1));
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
            }
        }
        
        // card is horizontally orianted.
        if(myRect.width >= 1.2*myRect.height){
            
            bool tr = false;
            double dBetweenP0_P1 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[1]);
            double dBetweenP0_P3 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[3]);
            if(dBetweenP0_P3 < dBetweenP0_P1){
                tr = true;
            }
            
            if(tr){
                dstArray.push_back(Point2f(0,maxHeight-1));
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
                
            }else{
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
                dstArray.push_back(Point2f(0,maxHeight-1));
            }
        }
        // card is Diamond orianted:
        if(myRect.width > 0.8*myRect.height && myRect.width < 1.2*myRect.height){
            
            //if dimond and equal
            bool tr = false;
            double dBetweenP0_P1 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[1]);
            double dBetweenP0_P3 = calcDistanceBetweenTwoPoints(verticesVec[0],verticesVec[3]);
            if(dBetweenP0_P3 > dBetweenP0_P1){
                tr = true;
            }
            
            if(tr){
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
                dstArray.push_back(Point2f(0,maxHeight-1));
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
            }else {
                dstArray.push_back(Point2f(0,maxHeight-1));
                dstArray.push_back(Point2f(0,0));
                dstArray.push_back(Point2f(maxWidth-1,0));
                dstArray.push_back(Point2f(maxWidth-1,maxHeight-1));
            }
        }
        
        //get Perspective Transform
        Mat m = getPerspectiveTransform(verticesVec, dstArray);
        // create outputcard
        Mat transformed_Card = Mat::zeros( cv::Size(maxWidth,maxHeight), CV_8UC3 );
        warpPerspective(sourceImage, transformed_Card, m, cv::Size(maxWidth,maxHeight));
        
        // **************** process corner to find Rank and Suit Corner ********************** //
        //cut the corener
        cv::Mat the_corner;
        Mat myCorner = transformed_Card(cv::Rect(0,0, 100,150));
        myCorner.copyTo(the_corner);
        transformed_Card.release();
        
        Mat rankANDSuit = lookForSuitandRank(the_corner);
        the_corner.release();
        if(rankANDSuit.empty()){
            //cout << "<< Something went wrong \n";
            return @"NA";
        }
        int splitLine = findSplitLineForRankSuit(rankANDSuit);
        
        cv::Mat myRank;
        cv::Mat mySuit;
        if (splitLine != 0 && splitLine < rankANDSuit.rows){
            //rank
            Mat tempRank = rankANDSuit(cv::Rect(0,0, rankANDSuit.cols,splitLine));
            tempRank.copyTo(myRank);
            resize(myRank, myRank, cv::Size(70,125));
            
            // suit
            Mat tempSuit = rankANDSuit(cv::Rect(0,splitLine, rankANDSuit.cols, (rankANDSuit.rows- splitLine)));  //(0,0, 35,150)); x,y,w,h
            tempSuit.copyTo(mySuit);
            resize(mySuit, mySuit, cv::Size(70,125));
        }else{
            //cout << "<< splitline problem \n";
            return @"NA" ;
        }
        myRank = getBoundingRec(myRank);
        mySuit = getBoundingRec(mySuit);
        
        
        // **************** compare ********************** //
        // compar; 1=rank, else = suit
        NSString *rank = comparetoTestingImages(myRank, 1);
        if ([rank isEqualToString:@"NA"]){
            return @"NA";
        }
        NSString *suit = comparetoTestingImages(mySuit, 2);
        NSString *comma = @",";
        NSString *rankSuit = [rank stringByAppendingString:comma];
        rankSuit = [rankSuit stringByAppendingString:suit];
        return rankSuit;
        
    }

    Mat getBoundingRec(Mat img){
        // **************** Find Bounding Rec for Rank Or Suit ********************** //
        vector<vector<cv::Point> > contours;
        vector<Vec4i> hierarchy;
        
        findContours( img, contours, hierarchy,CV_RETR_EXTERNAL , CV_CHAIN_APPROX_SIMPLE,cv::Point(0,0));
        
        int largest_contour_index= 0;
        if(contours.size() != 1){
            //find the largest contours
            int largest_area=0;
            // iterate through each contour.
            for( int i = 0; i< contours.size(); i++ )
            {
                //  Find the area of contour
                double a=contourArea( contours[i],false);
                if(a>largest_area){
                    largest_area=a;
                    // Store the index of largest contour
                    largest_contour_index=i;
                }
            }
        }
        //Get bounding rec info for biggest contours
        cv::Rect myRect = boundingRect(contours[largest_contour_index]);
        // draw bounding rec
        cv::Mat Q_img;
        Mat Q_Ref = img(myRect);
        Q_Ref.copyTo(Q_img);
        // resize  to match testing images
        resize(Q_img, Q_img, cv::Size(70,125));
        return Q_img;
    } // Mark:End of Bounding Rect

    Mat lookForSuitandRank(Mat source){
        Mat img = source;
        cvtColor(img, img, CV_BGR2GRAY);
        GaussianBlur(img,img,cv::Size(3,3),0);
        threshold(img, img, 0, 255,THRESH_BINARY+THRESH_OTSU);
        
        ///////// Look for Vertical start point ///////////
        int startCal = 0;
        int countWCals = 0;
        for (int col = 0 ; col < img.cols ; col++){
            // stop if when you find first Cal
            if(startCal != 0){
                break;
            }
            
            int wPix = 0;
            int bPix = 0;
            int bPixSeq = 0;
            int pixValue = 0;
            int previous_color = 0;
            for(int row = 0 ; row < img.rows ; row++){
                pixValue = (int)img.at<uchar>(row, col);
                if(pixValue == 255){
                    wPix++;
                }
                //CHECK: IF at least 4 white pix in top of the col
                if(wPix > 3){
                    if(pixValue == 0){
                        bPix++;
                        if(previous_color == 0){
                            bPixSeq++;
                        }
                    }
                    if(pixValue == 255 && bPix !=0){
                        previous_color = 255;
                    }
                }
            }// Row For Loop END
            
            // CHECK: count white cols, if no black pix and a lot of white pix
            if(bPix == 0 && wPix > 80){
                countWCals++;
            }
            // CHECK: if After at least 1 white cols
            if(countWCals > 1){
                //CHECK: if bPixseq is in range 2-49
                if(bPixSeq > 1 && bPixSeq< 50){
                    startCal = col;
                    break;
                }
            }
        }// end of for Col
        
        //cout<< startCal << "<<< Start Cal \n";
        if(startCal == 0 ){
            Mat empty;
            return empty;
        }
        
        
        ///////////// Look for v end point ////////////
        int endCal = 0;
        for (int col = startCal+3 ; col < img.cols ; col++){
            // stop if when you find end Cal
            if(endCal != 0){
                break;
            }
            
            int wPix = 0;
            double bPix = 0;
            int pixValue =0;
            int previous_color = 0;
            int bSeqPix = 0;
            
            for(int row = 0 ; row < img.rows ; row++){
                pixValue = (int)img.at<uchar>(row, col);
                
                if(pixValue == 255){
                    wPix++;
                }
                // after 5 white pix
                if(wPix > 4){
                    if(pixValue == 0){
                        bPix++;
                        if(previous_color == 0){
                            bSeqPix++;
                        }
                        
                    }
                    
                    if(pixValue == 255 && bPix !=0){
                        previous_color = 255;
                    }
                    
                }
            }// end of For Loop for Row.
            double blackPer = 0.0;
            blackPer = (bPix/150)*100;
            
            // Check If black pix 0,1 || If it end with black pix
            //This Good with all cards for: H:TR+TL, V:TL+TR , D:TR+TL
            if(bPix < 2  ){
                endCal = col;
                break;
            }
            
            if(blackPer > 49 && blackPer > 2  ){
                if(pixValue == 0){
                    endCal = col;
                    break;
                }
                
            }
        }// end of for Col
        
        //cout<< endCal << "<<< endCal \n";
        if(endCal == 0 ){
            Mat empty;
            return empty;
        }
        
        
        
        ///////////// Look for H start point //////////////
        int startRow = 0;
        int endRow = 0;
        
        int whiteRowsCounter =0;
        int previousColor = 255;
        int changes_counter =0;
        int bRowsCounter = 0;
        int wRowsCounter = 0;
        
    //    int colSearshDest = endCal-startCal;
    //    int endSearshCol = endCal - ceil(colSearshDest/4);
        for (int row = 0 ; row < img.rows ; row++){
            int rowColor = 255;
            int bPixSeq =0;
            
            //<= endSearshCol
            for(int col = startCal ; col <= endCal; col++){
                int pixValue = (int)img.at<uchar>(row, col);
                if(pixValue == 0){
                    bPixSeq++;
                }
                if(bPixSeq>1){
                    rowColor = 0;
                    break;
                }
                
            }// end Col Loop
            
            if(rowColor == 255){
                whiteRowsCounter++;
            }
            
            if(whiteRowsCounter > 5){
                
                
                if(rowColor == 0 && rowColor != previousColor ){
                    bRowsCounter++;
                    if(bRowsCounter > 1){
                        previousColor = rowColor;
                        changes_counter++;
                        if(changes_counter == 1){
                            startRow = row-1;
                        }
                        bRowsCounter = 0;
                        wRowsCounter =0;
                    }
                    
                }
                
                if(rowColor == 255 && rowColor != previousColor){
                    wRowsCounter++;
                    if(wRowsCounter > 1){
                        previousColor = rowColor;
                        changes_counter++;
                        if(changes_counter == 4){
                            endRow = row-1;
                            break;
                        }
                        bRowsCounter = 0;
                        wRowsCounter =0;
                    }
                    
                    
                }
            }
        }
        
        //cout<< startRow << "startRow\n";
        //cout<< endRow << "endRow \n";
        if(startRow == 0 || endRow == 0){
            Mat empty;
            return empty;
        }
        
        // Cut the image
        if(endCal - startCal > 5 && endRow-startRow > 5){
            // Cut image
            cv::Mat the_corner;
            Mat myCorner = source(cv::Rect(startCal,startRow,endCal-startCal,endRow-startRow ));  // (x, y, width, h)
            myCorner.copyTo(the_corner);
            
            resize(the_corner, the_corner,cv::Size(),10,10);
            cvtColor(the_corner, the_corner, CV_BGR2GRAY);
            GaussianBlur(img,img,cv::Size(3,3),0);
            threshold(the_corner, the_corner, 0, 255,THRESH_BINARY_INV+THRESH_OTSU);
            return the_corner;
        }
        Mat empty;
        return empty;
    }// Mark:- end of: lookForSuitandRank()

    int findSplitLineForRankSuit(Mat img){
        int splitLine = 0;
        
        int wRowsNum = 0;
        for (int row = 0 ; row < img.rows ; row++){
            
            int rowColor = 0;
            int wPixSeq = 0;
            for(int col = 0 ; col < img.cols; col++){
                int pixValue = (int)img.at<uchar>(row, col);
                if(pixValue == 255){
                    wPixSeq++;
                }
                if(wPixSeq>1){
                    rowColor = 255;
                    break;
                }
            }// end Col Loop
            
            if(rowColor == 255){
                wRowsNum++;
            }
            
            if(wRowsNum > 3){
                if(rowColor == 0){
                    splitLine = row+1;
                }
                
            }
        }
        
        return splitLine;
    }// Mark:- End Of: findSplitLineForRankSuit()



    // start:- comparetoTestingImages()
    NSString* comparetoTestingImages(Mat query_mat, int option){
        vector<cv::Mat> testMats;
        testMats = loadTestingImges(option);
        int lowestP = 10000;
        int index_ofLowestP = -1;
        for(int i=0;i<testMats.size();i++){
            Mat test_img = testMats[i];
            Mat comp_result;
            compare(test_img,query_mat, comp_result , cv::CMP_NE );
            int percentage  = countNonZero(comp_result);
            if(percentage < lowestP){
                lowestP = percentage;
                index_ofLowestP = i;
            }
        }
        cout<< lowestP << " :the confidnace of " << option << "\n";
        
        if(option == 1){
            if(index_ofLowestP != -1 && lowestP <= 2000){ //<= 2500
                    switch (index_ofLowestP) {
                        case 0: return @"A";
                            break;
                        case 1: return @"K";
                            break;
                        case 2: return @"Q";
                            break;
                        case 3: return @"J";
                            break;
                        case 4: return @"10";
                            break;
                        case 5: return @"9";
                            break;
                        case 6: return @"8";
                            break;
                        case 7: return @"7";
                            break;
                        default: return @"NA";
                            break;
                    }
            }
        }else{
            if(index_ofLowestP != -1 && lowestP <= 1250){
                switch (index_ofLowestP) {
                    case 0: return @"heart";
                        break;
                    case 1: return @"diamond";
                        break;
                    case 2: return @"spade";
                        break;
                    case 3: return @"club";
                        break;
                    default: return @"NA";
                        break;
                }
            }
        }
        
       
        
        
        
    //    if(index_ofLowestP != -1 && lowestP <= 2000){ //<= 2500
    //        if(option == 1){
    //            switch (index_ofLowestP) {
    //                case 0: return @"A";
    //                    break;
    //                case 1: return @"K";
    //                    break;
    //                case 2: return @"Q";
    //                    break;
    //                case 3: return @"J";
    //                    break;
    //                case 4: return @"10";
    //                    break;
    //                case 5: return @"9";
    //                    break;
    //                case 6: return @"8";
    //                    break;
    //                case 7: return @"7";
    //                    break;
    //                default: return @"NA";
    //                    break;
    //            }
    //        }else{
    //            switch (index_ofLowestP) {
    //                case 0: return @"heart";
    //                    break;
    //                case 1: return @"diamond";
    //                    break;
    //                case 2: return @"spade";
    //                    break;
    //                case 3: return @"club";
    //                    break;
    //                default: return @"NA";
    //                    break;
    //            }
    //        }
    //    }
        return @"NA";
    } // end:- comparetoTestingImages()

    // start:- load testing imges()
    vector<Mat> loadTestingImges(int option){
        // 1= load ranks, else = load suits
        vector< NSString*> imNames;
        if(option == 1){
            //cout<< "<< test rank\n";
            imNames.push_back(@"A");
            imNames.push_back(@"K");
            imNames.push_back(@"Q");
            imNames.push_back(@"J");
            imNames.push_back(@"10");
            imNames.push_back(@"9");
            imNames.push_back(@"8");
            imNames.push_back(@"7");
        }else{
            //cout<< "<< test suit\n";
            imNames.push_back(@"heart");
            imNames.push_back(@"diamond");
            imNames.push_back(@"spade");
            imNames.push_back(@"club");
        }
        vector<cv::Mat> matArray;
        NSString *imType = @"jpg";
        // Load suit image this works with jpg
        for(int i=0; i<imNames.size(); i++){
            NSString *path = [[NSBundle mainBundle] pathForResource:imNames[i] ofType:imType];
            const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
            
            Mat img = imread(cpath);
            //TO fix color problem
            cvtColor(img, img, COLOR_BGR2RGB);
            
            resize(img, img, cv::Size(),10,10);
            // to gray, blur, threshold
            cvtColor(img, img, CV_BGR2GRAY);
            threshold(img,img,120,255,THRESH_BINARY_INV);
            
            //Find bounding rec
            vector<vector<cv::Point> > im_contours;
            vector<Vec4i> im_hierarchy;
            findContours( img, im_contours, im_hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE,cv::Point(0,0));
            
            //find the largest contours
            int largest_area=0;
            int largest_contour_index=0;
            // iterate through each contour.
            for( int i = 0; i< im_contours.size(); i++ )
            {
                //  Find the area of contour
                double a=contourArea( im_contours[i],false);
                if(a>largest_area){
                    largest_area=a;
                    // Store the index of largest contour
                    largest_contour_index=i;
                }
            }
            
            cv::Rect imgRect = boundingRect(im_contours[largest_contour_index]);
            
            cv::Mat bounded_im;
            Mat imRef = img(imgRect);
            imRef.copyTo(bounded_im);
            
            resize(bounded_im, bounded_im, cv::Size(70,125));
            matArray.push_back(bounded_im);
        }
        return matArray;
    }// end:- load testing imges()


    // start:- calcDistanceBetweenTwoPoints()
    double calcDistanceBetweenTwoPoints(cv::Point2f a,cv::Point2f b){
        double d = sqrt(pow(a.x-b.x,2)+pow(a.y-b.y,2));
        return d;
    }// end:- calcDistanceBetweenTwoPoints()

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
