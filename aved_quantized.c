//
// TO RUN: gcc aved_quantized.c -o aved_quantized_exe -std=c99
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <math.h>

#define high_threshold 48
#define low_threshold 12
// #define MPI acos(-1.0)
#define MPI 3.14

#define BITS 10
#define QUANT_VAL (1 << BITS)
#define QUANTIZE_F(f) (int)(((float)(f) * (float)QUANT_VAL))
#define QUANTIZE_I(i) (int)((int)(i) * (int)QUANT_VAL)
#define DEQUANTIZE(i) (int)((int)(i) / (int)QUANT_VAL)

#define K 1.646760258121066
#define CORDIC_1K QUANTIZE_F(1/K)
#define PI QUANTIZE_F(MPI)
#define HALF_PI QUANTIZE_F(MPI/2)

#define CORDIC_NTAB 16

const int CORDIC_TABLE[16] = {804, 474, 250, 127, 63, 31, 15, 8, 4, 2, 1, 0, 0, 0, 0, 0};

struct pixel {
    unsigned char b;
    unsigned char g;
    unsigned char r;
};

// Read BMP file and extract the pixel values (store in data) and header (store in header)
// data is data[0] = BLUE, data[1] = GREEN, data[2] = RED, etc...
int read_bmp(FILE *f, unsigned char* header, int *height, int *width, struct pixel* data)
{
    printf("reading file...\n");
    // read the first 54 bytes into the header
    if (fread(header, sizeof(unsigned char), 54, f) != 54)
    {
        printf("Error reading BMP header\n");
        return -1;
    }
    
    // get height and width of image
    int w = (int)(header[19] << 8) | header[18];
    int h = (int)(header[23] << 8) | header[22];
    
    // Read in the image
    int size = w * h;
    if (fread(data, sizeof(struct pixel), size, f) != size){
        printf("Error reading BMP image\n");
        return -1;
    }
    
    *width = w;
    *height = h;
    return 0;
}

void write_rgb_bmp(const char *filename, unsigned char* header, struct pixel* data) {
    FILE* file = fopen(filename, "wb");
    
    // get height and width of image
    int width = (int)(header[19] << 8) | header[18];
    int height = (int)(header[23] << 8) | header[22];
    int size = width * height;
    
    fwrite(header, sizeof(unsigned char), 54, file);
    
    fwrite(data, sizeof(struct pixel), size, file);
    fclose(file);
}

// Write the grayscale image to disk.
void write_grayscale_bmp(const char *filename, unsigned char* header, unsigned char* data) {
    FILE* file = fopen(filename, "wb");
    
    // get height and width of image
    int width = (int)(header[19] << 8) | header[18];
    int height = (int)(header[23] << 8) | header[22];
    int size = width * height;
    struct pixel * data_temp = (struct pixel *)malloc(size*sizeof(struct pixel));
    
    // write the 54-byte header
    fwrite(header, sizeof(unsigned char), 54, file);
    int y, x;
    
    // the r field of the pixel has the grayscale value. copy to g and b.
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            (*(data_temp + y*width + x)).b = (*(data + y*width + x));
            (*(data_temp + y*width + x)).g = (*(data + y*width + x));
            (*(data_temp + y*width + x)).r = (*(data + y*width + x));
        }
    }
    
    size = width * height;
    fwrite(data_temp, sizeof(struct pixel), size, file);
    
    free(data_temp);
    fclose(file);
}

// Determine the grayscale 8 bit value by averaging the r, g, and b channel values.
void convert_to_grayscale(struct pixel * data, int height, int width, unsigned char *grayscale_data)
{
    for (int i = 0; i < width*height; i++) {
        grayscale_data[i] = (data[i].r + data[i].g + data[i].b) / 3;
        //printf("%3d: %02x %02x %02x  ->  %02x\n", i,data[i].r, data[i].g, data[i].b, grayscale_data[i]);
    }
}

// Gaussian blur.
void gaussian_blur(unsigned char *in_data, int height, int width, unsigned char *out_data) {
    unsigned int gaussian_filter[5][5] = {
        { 2, 4, 5, 4, 2 },
        { 4, 9,12, 9, 4 },
        { 5,12,15,12, 5 },
        { 4, 9,12, 9, 4 },
        { 2, 4, 5, 4, 2 }
    };
    int x, y, i, j;
    unsigned int numerator_r, denominator;
    
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            numerator_r = 0;
            denominator = 0;
            for (j = -2; j <= 2; j++) {
                for (i = -2; i <= 2; i++) {
                    if ( (x+i) >= 0 && (x+i) < width && (y+j) >= 0 && (y+j) < height) {
                        unsigned char d = in_data[(y+j)*width + (x+i)];
                        numerator_r += d * gaussian_filter[i+2][j+2];
                        denominator += gaussian_filter[i+2][j+2];
                    }
                }
            }
            out_data[y*width + x] = numerator_r / denominator;
        }
    }
}

void edge_detect(unsigned char in_data[3][3], unsigned char *out_data)
{
    // Definition of Sobel filter in horizontal direction
    const int horizontal_operator[3][3] = {
        { -1,  0,  1 },
        { -2,  0,  2 },
        { -1,  0,  1 }
    };
    const int vertical_operator[3][3] = {
        { -1,  -2,  -1 },
        {  0,   0,   0 },
        {  1,   2,   1 }
    };
    
    int horizontal_gradient = 0;
    int vertical_gradient = 0;
    
    for (int j = 0; j < 3; j++)
    {
        for (int i = 0; i < 3; i++)
        {
            horizontal_gradient += in_data[j][i] * horizontal_operator[i][j];
            vertical_gradient += in_data[j][i] * vertical_operator[i][j];
            //printf("h: %d * %d\n", in_data[j][i], horizontal_operator[i][j] );
            //printf("v: %d * %d\n", in_data[j][i], vertical_operator[i][j] );
        }
    }
    
    // Check for overflow
    int v = (abs(horizontal_gradient) + abs(vertical_gradient)) / 2;
    //printf("grad: %d\n\n", v);
    *out_data = (unsigned char)(v > 255 ? 255 : v);
}

void sobel_filter(unsigned char *in_data, int height, int width, unsigned char *out_data)
{
    unsigned char buffer[3][3];
    unsigned char data = 0;
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            data = 0;
            
            // Along the boundaries, set to 0
            if (y != 0 && x != 0 && y != height-1 && x != width-1)
            {
                for (int j = -1; j <= 1; j++)
                {
                    for (int i = -1; i <= 1; i++)
                    {
                        buffer[j+1][i+1] = in_data[(y+j)*width + (x+i)];
                    }
                }
                
                edge_detect( buffer, &data );
            }
            
            out_data[y*width + x] = data;
        }
    }
}

void non_maximum_suppressor(unsigned char *in_data, int height, int width, unsigned char *out_data)
{
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // Along the boundaries, set to 0
            if (y == 0 || x == 0 || y == height-1 || x == width-1) {
                out_data[y*width + x] = 0;
                continue;
            }
            unsigned int north_south =
            in_data[(y-1)*width + x] + in_data[(y+1)*width + x];
            unsigned int east_west =
            in_data[y*width + x - 1] + in_data[y*width + x + 1];
            unsigned int north_west =
            in_data[(y-1)*width + x - 1] + in_data[(y+1)*width + x + 1];
            unsigned int north_east =
            in_data[(y+1)*width + x - 1] + in_data[(y-1)*width + x + 1];
            
            out_data[y*width + x] = 0;
            
            if (north_south >= east_west && north_south >= north_west && north_south >= north_east) {
                if (in_data[y*width + x] > in_data[y*width + x - 1] &&
                    in_data[y*width + x] >= in_data[y*width + x + 1])
                {
                    out_data[y*width + x] = in_data[y*width + x];
                }
            } else if (east_west >= north_west && east_west >= north_east) {
                if (in_data[y*width + x] > in_data[(y-1)*width + x] &&
                    in_data[y*width + x] >= in_data[(y+1)*width + x])
                {
                    out_data[y*width + x] = in_data[y*width + x];
                }
            } else if (north_west >= north_east) {
                if (in_data[y*width + x] > in_data[(y-1)*width + x + 1] &&
                    in_data[y*width + x] >= in_data[(y+1)*width + x - 1])
                {
                    out_data[y*width + x] = in_data[y*width + x];
                }
            } else {
                if (in_data[y*width + x] > in_data[(y-1)*width + x - 1] &&
                    in_data[y*width + x] >= in_data[(y+1)*width + x + 1])
                {
                    out_data[y*width + x] = in_data[y*width + x];
                }
            }
        }
    }
}

// Only keep pixels that are next to at least one strong pixel.
void hysteresis_filter(unsigned char *in_data, int height, int width, unsigned char *out_data) {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // Along the boundaries, set to 0
            if (y == 0 || x == 0 || y == height-1 || x == width-1) {
                out_data[y*width + x] = 0;
                continue;
            }
            
            // If pixel is strong or it is somewhat strong and at least one
            // neighbouring pixel is strong, keep it. Otherwise zero it.
            if (in_data[y*width + x] > high_threshold ||
                (in_data[y*width + x] > low_threshold &&
                 (in_data[(y-1)*width + x - 1] > high_threshold ||
                  in_data[(y-1)*width + x] > high_threshold ||
                  in_data[(y-1)*width + x + 1] > high_threshold ||
                  in_data[y*width + x - 1] > high_threshold ||
                  in_data[y*width + x + 1] > high_threshold ||
                  in_data[(y+1)*width + x - 1] > high_threshold ||
                  in_data[(y+1)*width + x] > high_threshold ||
                  in_data[(y+1)*width + x + 1] > high_threshold))
                ){
                out_data[y*width + x] = in_data[y*width + x];
            } else {
                out_data[y*width + x] = 0;
            }
        }
    }
}

int find_max(unsigned char* data, int width, int height) {
    int max = 0;
    
    for (int i = 0; i < width*height; i++) {
        if (data[i] > max) {
            max = data[i];
        }
    }
    
    // printf("img_data_max : %d \n", max );
    return max;
}

int find_max_int(unsigned int* data, int width, int height) {
    int max = 0;
    
    for (int i = 0; i < width*height; i++) {
        if (data[i] > max) {
            max = data[i];
        }
    }
    
    // printf("accu_max : %d \n", max );
    return max;
}

void cordic_stage(short k, short c, short *x, short *y, short *z) {
    // inputs
    short xk = *x;   // cosine
    short yk = *y;   // sine
    short zk = *z;   // r : angle in radian
    // cordic stage
    short d = (zk >= 0) ? 0 : -1;
    short tx = xk - (((yk >> k) ^ d) - d);  // cosine
    short ty = yk + (((xk >> k) ^ d) - d);  // sine
    short tz = zk - ((c ^ d) - d);    // c: cordic_table[i]
    // outputs
    *x = tx;
    *y = ty;
    *z = tz;
}


void cordic(int rad, short *s, short *c) {
    short x = CORDIC_1K, y = 0;
    int r = rad;
    // printf("PI: %d, HALF_PI: %d;  \n",PI, HALF_PI); // PI=3215; HALF_PI=1607
    while ( r > PI ) r -= 2*PI;
    while ( r < -PI ) r += 2*PI;
    if ( r > HALF_PI ) {
        r -= PI; x = -x; y = -y;
    }
    else if ( r < -HALF_PI ) {
        r += PI; x = -x; y = -y;
    }
    short z = r;
    for ( int k = 0; k < CORDIC_NTAB; k++ ) {
        cordic_stage(k, CORDIC_TABLE[k], &x, &y, &z); // Cycle through 45deg ... 0, 16 stages
    }
    *c = x;
    *s = y;
}

int HoughTransform(unsigned char* img_data, int w, int h,  int hough_h, int accu_h, int accu_w, unsigned int* accu) { // hough_h is quantized
    
    short sin_theta;
    short cos_theta;
    
    // double center_x = w/2;
    // int center_x = QUANTIZE_I(w/2);
//    int center_x = floor(w/2);
    int center_x = w >> 1;
    // double center_y = h/2;
    //  int center_y = QUANTIZE_I(h/2);
    int center_y = h >> 1;

    for(int y=0;y<h;y++)
    {
        for(int x=0;x<w;x++)
        {
            if( img_data[ (y*w) + x] > 50 )
            {

                for(int t=0;t<180;t++)
                {
                    // double r = ( ((double)x - center_x) * cos((double)t * MPI/180)) + (((double)y - center_y) * sin((double)t * MPI/180));

                    int x_p  =  x - center_x;
                    int y_p  =  y - center_y;

                    int theta = QUANTIZE_F(t*MPI/180);
                    cordic(theta, &sin_theta, &cos_theta);  // s is sine, c is cosine. Theta is in radian, quantized

                    int r = x_p*cos_theta + y_p * sin_theta; // r is quantized
                    int index = DEQUANTIZE(r + hough_h);     // hough_h is also quantized
                    //  accu[ (int)((round(r + hough_h) * 180.0)) + t]++;
                    accu[index*180 + t]++;
                    //	      printf("index+t: %d; accu: %d, rho: %d, t: %d, hough_h: %d \n", index*180+t,accu[index + t],r,t,hough_h);
                }
            }
        }
    }
    
    return 0;
}

// Search accumulator for all lines greater than a certain threshold
int HoughGetLines(unsigned char* in_data, unsigned int* accu, int w, int h, int accu_h, int accu_w, struct pixel * out_data) {
    
    short sin_theta;
    short cos_theta;
    
//    int accu_threshold = (int) ceil(find_max_int(accu, accu_w, accu_h)*0.5);
    int accu_threshold = find_max_int(accu, accu_w, accu_h) >> 1;
//    printf("accu_h: %d,  accu_threshold: %d \n", accu_h,accu_threshold);
//    printf("accu_w: %d,  w: %d,  h: %d \n", accu_w,w,h);
    
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            (*(out_data + y*w + x)).b = (*(in_data + y*w + x));
            (*(out_data + y*w + x)).g = (*(in_data + y*w + x));
            (*(out_data + y*w + x)).r = (*(in_data + y*w + x));
        }
    }
    
    if(accu == 0)  return 0;
    
    int i = 0;
    for(int r=0;r<accu_h;r++)
    {
        for(int t=0;t<accu_w;t++)
        {
            // if ((int)accu[(r*accu_w) + t] != 0)
            if(accu[(r*accu_w) + t] >= accu_threshold)
            {
//                printf("accu > threshold: accu: %d,  accu_index: %d; rho: %d,  theta: %d \n", accu[(r*accu_w)+t],(r*accu_w)+t,r,t);
                
                //    Thresholding /////////////////////////////////////////////////////////////////////////////
                
                int max = accu[(r*accu_w) + t];
                for(int ly=-3;ly<=3;ly++)
                {
                    for(int lx=-3;lx<=3;lx++)
                    {
                        if( (ly+r>=0 && ly+r<accu_h) && (lx+t>=0 && lx+t<accu_w) )
                        {
                            if( (int)accu[( (r+ly)*accu_w) + (t+lx)] > max )
                            {
                                max = accu[( (r+ly)*accu_w) + (t+lx)];
                                ly = lx = 5;
                            }
                        }
                    }
                }
                if(max > (int)accu[(r*accu_w) + t])
                    continue;
                
                //    Create finite lines ///////////////////////////////////////////////////////////////////////
                
                int x1, y1, x2, y2;
                x1 = y1 = x2 = y2 = 0;

                int theta = QUANTIZE_F(t*MPI/180);
                cordic(theta, &sin_theta, &cos_theta);  // s is sine, c is cosine. Theta is in radian, quantized
                
                int accu_h_div2 = accu_h >> 1;
                int w_div2      = w >> 1;
                int h_div2      = h >> 1;
                int rho_quant = QUANTIZE_I(r - accu_h_div2);

                if(t >= 45 && t <= 135)
                {
                    //y = (r - x cos(t)) / sin(t)
                    x1 = 0;
                    //              y1 = ((double)(r-(accu_h/2)) - ((x1 - (w/2) ) * cos(t * MPI/180))) / sin(t * MPI/180) + (h / 2);
                    y1  = ((rho_quant - (x1 - w_div2) * cos_theta) / sin_theta) + h_div2;
                    x2 = w - 0;
                    // y2 = ((double)(r-(accu_h/2)) - ((x2 - (w/2) ) * cos(t * MPI/180))) / sin(t * MPI/180) + (h / 2);
                    y2 = ( rho_quant - (x2 - w_div2) * cos_theta) / sin_theta + h_div2;
                }
                else
                {
                    //x = (r - y sin(t)) / cos(t);
                    y1 = 0;
                    // x1 = ((double)(r-(accu_h/2)) - ((y1 - (h/2) ) * sin(t * MPI/180))) / cos(t * MPI/180) + (w / 2);
                    x1 = ((rho_quant - (y1 - h_div2) * sin_theta) / cos_theta) + w_div2;
                    y2 = h - 0;
                    // x2 = ((double)(r-(accu_h/2)) - ((y2 - (h/2) ) * sin(t * MPI/180))) / cos(t * MPI/180) + (w / 2);
                    x2 = ((rho_quant - (y2 - h_div2) * sin_theta) / cos_theta) + w_div2;
                }
                
                //    Project lines back onto the image /////////////////////////////////////////////////////////
                
                if (x1 > (w - 1)) x1 = (w - 1);
                if (x2 > (w - 1)) x2 = (w - 1);
                if (y1 > (h - 1)) y1 = (w - 1);
                if (y2 > (h - 1)) y2 = (w - 1);
                
                int start_y, end_y, start_x, end_x, change_y;
                int delta_x;
                int delta_y;
                int x_direction;
                int y_direction;
                
                if (x1 > x2) {
                    delta_x     = x1 - x2;
                    x_direction = 1;     // decrement
                } else {
                    delta_x     = x2 - x1;
                    x_direction = 0;     // increment
                }
                
                if (y1 > y2) {
                    delta_y     = y1 - y2;
                    y_direction = 1;     // decrement
                } else {
                    delta_y     = y2 - y1;
                    y_direction = 0;     // increment
                }
                
                start_x = x1;
                end_x   = x2;
                start_y = y1;
                end_y   = y2;
                
                printf("drawing line from (%d, %d) to (%d, %d)\n", x1, y1, x2, y2);
//                printf("start_x:%d,  end_x: %d; start_y: %d, end_y: %d)\n", start_x, end_x, start_y, end_y);
                
                //            double slope = ceil (y2 - y1) / (x2 - x1);

                int slope  = QUANTIZE_I(delta_y) / delta_x;
//                int slope2 = floor(slope);
                
                int start_yy = QUANTIZE_I(start_y);
                int end_yy   = QUANTIZE_I(end_y);
                int i_start = y_direction ? end_yy   : start_yy;
                int i_end   = y_direction ? start_yy : end_yy;
                
                int x = start_x;
                
                // double slope2 = (ceil (slope));
                // printf("slope %f %f %d\n", slope, slope2, slope3);
                printf("slope: %d \n", slope);
                
                int y_pixel = start_yy;
                for (int yy = i_start; yy <= i_end; yy = yy + slope) {
                    if (y_direction == 1) {
                        y_pixel = y_pixel - slope;
                    } else {
                        y_pixel = y_pixel + slope;
                    }
                    int y = DEQUANTIZE(y_pixel);
                    (*(out_data + y*w + x)).r = 254;
                    (*(out_data + y*w + x)).b = 0;
                    (*(out_data + y*w + x)).g = 0;
                    // printf("drawing pixel at: (%d, %d, %d)\n", x, y,y*w+x);
                    x = x_direction ? x-1 : x+1;
                }
            } // if accu > accu_threshold
        } // for t loop
    } // for r loop
    
    return 0;
}  // int HoughGetLines

int main(int argc, char *argv[]) {
    /*
     struct pixel *rgb_data = (struct pixel *)malloc(720*540*sizeof(struct pixel));
     unsigned char *gs_data = (unsigned char *)malloc(720*540*sizeof(unsigned char));
     unsigned char *gb_data = (unsigned char *)malloc(720*540*sizeof(unsigned char));
     unsigned char *sobel_data = (unsigned char *)malloc(720*540*sizeof(unsigned char));
     unsigned char *nms_data = (unsigned char *)malloc(720*540*sizeof(unsigned char));
     unsigned char *h_data = (unsigned char *)malloc(720*540*sizeof(unsigned char));
     */
    unsigned char header[64];
    int height, width;
    
    // Check inputs
    if (argc < 2) {
        printf("Usage: edgedetect <BMP filename>\n");
        return 0;
    }
    
    FILE * f = fopen(argv[1],"rb");
    if ( f == NULL ) return 0;
    
    struct pixel *rgb_data = (struct pixel *)malloc(1024*1024*sizeof(struct pixel));
    
    // read the bitmap
    read_bmp(f, header, &height, &width, rgb_data);
    
    unsigned char *gs_data = (unsigned char *)malloc(width*height*sizeof(unsigned char));
    unsigned char *gb_data = (unsigned char *)malloc(width*height*sizeof(unsigned char));
    unsigned char *sobel_data = (unsigned char *)malloc(width*height*sizeof(unsigned char));
    unsigned char *nms_data = (unsigned char *)malloc(width*height*sizeof(unsigned char));
    unsigned char *h_data = (unsigned char *)malloc(width*height*sizeof(unsigned char));
    
    /// Grayscale conversion
    convert_to_grayscale(rgb_data, height, width, gs_data);
    write_grayscale_bmp("stage0_grayscale.bmp", header, gs_data);
    
    /// Gaussian filter
    gaussian_blur(gs_data, height, width, gb_data);
    write_grayscale_bmp("stage1_gaussian.bmp", header, gb_data);
    
    /// Sobel operator
    sobel_filter(gb_data, height, width, sobel_data);
    write_grayscale_bmp("stage2_sobel.bmp", header, sobel_data);
    
    /// Non-maximum suppression
    non_maximum_suppressor(sobel_data, height, width, nms_data);
    write_grayscale_bmp("stage3_nonmax_suppression.bmp", header, nms_data);
    
    /// Hysteresis
    hysteresis_filter(nms_data, height, width, h_data);
    write_grayscale_bmp("stage4_hysteresis.bmp", header, h_data);
    
    // Hough Transform
    
    //Create the accu
    // double hough_h = ((sqrt(2.0) * (double)(height > width? height : width)) / 2.0);
    int sqrt2_quant = QUANTIZE_F(1.414213562);
    int hough_h = sqrt2_quant * ((height > width? height : width) / 2.0);
    int accu_h = DEQUANTIZE(hough_h * 2.0); // -r -> +r
    int accu_w = 180;
    unsigned int* accu = (unsigned int*)calloc(accu_h * accu_w, sizeof(unsigned int));
    int accu_threshold = 175;
    
    int size = width*height;
    struct pixel * rgb_out_data = (struct pixel *)malloc(size*sizeof(struct pixel));
    
    int max_pixel_val = find_max(h_data, width, height);
    // printf("max value of canny edge image is %d\n", max_pixel_val);
    
    HoughTransform(h_data, width, height, hough_h, accu_h, accu_w, accu); // hough_h is quantized
    HoughGetLines(h_data, accu, width, height, accu_h, accu_w, rgb_out_data);
    write_rgb_bmp("HoughTransform_Quantized.bmp", header, rgb_out_data);
    
    return 0;
}

// Quantizing
// constants should be quantized
// 20 bits for the mantissa, 12 bits for the fractional, multiply by 2^12
// prequantize numerator before you divide
