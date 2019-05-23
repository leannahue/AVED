#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#define high_threshold 48
#define low_threshold 12


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

    int Hough::Transform(unsigned char* img_data, int w, int h) {

      //Create the accu
      double hough_h = ((sqrt(2.0) * (double)(h>w?h:w)) / 2.0);
      accu_h = hough_h * 2.0; // -r -> +r
      accu_w = 180;

      accu = (unsigned int*)calloc(accu_h * accu_w, sizeof(unsigned int));

      double center_x = w/2;
      double center_y = h/2;

      for(int y=0;y<h;y++)
      {
        for(int x=0;x<w;x++)
        {
          if( img_data[ (y*w) + x] > 250 )
          {
            for(int t=0;t<180;t++)
            {
              double r = ( ((double)x - center_x) * cos((double)t * DEG2RAD)) + (((double)y - center_y) * sin((double)t * DEG2RAD));
              accu[ (int)((round(r + hough_h) * 180.0)) + t]++;
            }
          }
        }
      }

      return 0;
    }

    std::vector< std::pair< std::pair<int, int>, std::pair<int, int>>> Hough::GetLines(int threshold) {
      std::vector< std::pair< std::pair<int, int>, std::pair<int, int>>> lines;

      if(accu == 0)  return lines;

      for(int r=0;r<accu_h;r++)
      {
        for(int t=0;t<accu_w;t++)
        {
          if((int)accu[(r*accu_w) + t] >= threshold)
          {
            //Is this point a local maxima (9x9)
            int max = accu[(r*accu_w) + t];
            for(int ly=-4;ly<=4;ly++)
            {
              for(int lx=-4;lx<=4;lx++)
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
            int x1, y1, x2, y2;
            x1 = y1 = x2 = y2 = 0;

            if(t >= 45 && t <= 135)
            {
              //y = (r - x cos(t)) / sin(t)
              x1 = 0;
              y1 = ((double)(r-(accu_h/2)) - ((x1 - (w/2) ) * cos(t * DEG2RAD))) / sin(t * DEG2RAD) + (h / 2);
              x2 = w - 0;
              y2 = ((double)(r-(accu_h/2)) - ((x2 - (w/2) ) * cos(t * DEG2RAD))) / sin(t * DEG2RAD) + (h / 2);
            }
            else
            {
              //x = (r - y sin(t)) / cos(t);
              y1 = 0;
              x1 = ((double)(r-(accu_h/2)) - ((y1 - (h/2) ) * sin(t * DEG2RAD))) / cos(t * DEG2RAD) + (w / 2);
              y2 = h - 0;
              x2 = ((double)(r-(accu_h/2)) - ((y2 - (h/2) ) * sin(t * DEG2RAD))) / cos(t * DEG2RAD) + (w / 2);
            }

            lines.push_back(std::pair< std::pair<int, int>, std::pair<int, int> >(std::pair<int, int>(x1,y1), std::pair<int, int>(x2,y2)));

          }
        }
      }

      std::cout << "lines: " << lines.size() << " " << threshold << std::endl;
      return lines;
    }

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

      return 0;
    }
