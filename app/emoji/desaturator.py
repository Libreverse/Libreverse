import os
from xml.etree import ElementTree as ET
import colorsys

def desaturate_color(color, saturation_factor=0.75):
    if color.startswith('#'):
        r = int(color[1:3], 16) / 255.0
        g = int(color[3:5], 16) / 255.0
        b = int(color[5:7], 16) / 255.0
        
        # Convert RGB to HLS (Hue, Lightness, Saturation)
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        
        # Desaturate by the given factor
        s *= saturation_factor
        
        # Convert back to RGB
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        
        # Convert to hex
        return '#{:02x}{:02x}{:02x}'.format(int(r * 255), int(g * 255), int(b * 255))
    return color  # If not a hex color, return unchanged

def process_svg(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    
    for elem in root.iter():
        if 'fill' in elem.attrib:
            elem.attrib['fill'] = desaturate_color(elem.attrib['fill'])
        if 'stroke' in elem.attrib:
            elem.attrib['stroke'] = desaturate_color(elem.attrib['stroke'])
    
    tree.write(filename)

def main():
    for filename in os.listdir('.'):
        if filename.endswith('.svg'):
            process_svg(filename)
    print("Desaturation completed for all SVG files in the current directory.")

if __name__ == "__main__":
    main()