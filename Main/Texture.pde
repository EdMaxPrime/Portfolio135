abstract class Texture {
  int txtWidth, txtHeight;
  
  /** Returns a vertical stripe, to scale depending on distance */
  abstract PImage getStripe(float where, double distance);
  /** Make the texture darker to simulate shading */
  abstract Texture darker();
  /** Returns a copy */
  abstract Texture copy();
}

/** The simplest kind of Texture, used for monochrome blocks */
public class OneColor extends Texture {
  color mycolor;
  public OneColor(color c) {
    mycolor = c;
    txtWidth = 16;
    txtHeight = 16;
  }
  
  /** The only relevant parameter is DISTANCE because that's used for foreshortening. Since this is 
      all one color, the location where the ray hit the block isn't important*/
  public PImage getStripe(float where, double distance) {
    distance = (distance <= 0)? .001 : distance; //cant be negative or zero
    PImage img = createImage(1, (int)(height / distance), RGB);
    img.loadPixels();
    for(int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = mycolor;
    }
    img.updatePixels();
    return img;
  }
  
  public OneColor darker() {
    colorMode(HSB, 360, 100, 100, 255);
    mycolor = color(hue(mycolor), saturation(mycolor), brightness(mycolor)/2, alpha(mycolor));
    colorMode(RGB, 255, 255, 255, 255);
    return this;
  }
  
  public OneColor copy() {
    OneColor t = new OneColor(mycolor);
    return t;
  }
}

class ImageTexture extends Texture {
  PImage img;
  color avgColor;
  
  public ImageTexture(PImage _img) {
    img = _img;
    txtWidth = img.width;
    txtHeight = img.height;
    img.loadPixels();
    computeAverageColor();
  }
  
  /** Returns a vertical stripe */
  PImage getStripe(float where, double distance) {
    distance = (distance <= 0)? .001 : distance; //cant be negative or zero
    if(where > 1.0) where -= floor(where);
    PImage stripe = createImage(1, (int)(height / distance), RGB);
    int xCoord = (int)(img.width * where);
    stripe.loadPixels(); //to edit the pixels of the image we return
    int correctionValue = 0; //sometimes texY is shifted down into negatives, this makes sure it isnt
    for(int y = 0; y < stripe.pixels.length; y++) {
      if(txtHeight < stripe.height) {
        stripe.pixels[y] = scaledTexel(xCoord, y, ((float)txtHeight) / stripe.height);
      } else {
        int convert = y * 256 - height * 128 + stripe.height * 128;
        int texY = ((convert * txtHeight) / stripe.height) / 256;
        if(y == 0) correctionValue = abs(texY);
        stripe.pixels[y] = img.pixels[(texY + correctionValue) * txtWidth + xCoord];
      }
    }
    stripe.updatePixels();
    return stripe;
  }
  /** Returns the appropriate color to use given the X coord
      of the texture and the Y coord of the new scaled texture;
      howMany is a ratio that will be replaced soon, right now
      it just tells us if we should try to do math or just give
      up because the scaled texture is too small and use the avgColor */
  private color scaledTexel(int xCoord, int scaledYCoord, float howMany) {
    if(howMany < 1) {
      return img.pixels[xCoord + txtWidth * floor(scaledYCoord * howMany)];
    } else {
      return avgColor;
    }
  }
  
  /** Computes the average color of this picture, will
      be used when the dimensions of this texture get
      too small */
  void computeAverageColor() {
    int r = 0, g = 0, b = 0, a = 0;
    for(color c : img.pixels) {
      r += red(c);
      g += green(c);
      b += blue(c);
      a += alpha(c);
    }
    int l = img.pixels.length;
    avgColor = color(r / l, g / l, b / l, a / l);
  }
  /** Make the texture darker to simulate shading */
  Texture darker() {
    colorMode(HSB, 360, 100, 100, 255);
    img.loadPixels();
    for(int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(hue(img.pixels[i]), saturation(img.pixels[i]), brightness(img.pixels[i])/2, alpha(img.pixels[i]));
    }
    img.updatePixels();
    colorMode(RGB);
    computeAverageColor();
    return this;
  }
  /** Returns a copy */
  Texture copy() {
    return new ImageTexture(img.copy());
  }
}