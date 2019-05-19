import getopt
import os
import re
import sys

# if no speed is specified use 30 mm/s for insertions
speed = 0

def primeCallback(match):
  # match will contain the destring prime ('detract' or 'insertion' block. group 1 will match the value of F)
  # feedrates are specified in mm/min, input is mm/s, replace Fvalue with user specified value
  return match.group(0).replace(match.group(1), str(speed*60))

def main(argv):
  inputfile = ''
  outputdir = ''
  global speed
  
  try:
    opts, args = getopt.getopt(argv,"h:ios",["inFile=","outDir=","speed="])
  except getopt.GetoptError:
    print('kissproc.py --inFile <inputfile> --outDir <outputdir> --speed <primespeed>')
    sys.exit(2)
  for opt, arg in opts:
    if opt == "-h":
      print('kissproc.py --inFile <inputfile> --outDir <outputdir> --speed <primespeed>')
      sys.exit()
    elif opt in ("--inFile"):
      inputfile = arg
    elif opt in ("--outDir"):
      outputdir = arg
    elif opt in ("--speed"):
      speed = int(arg)

  f = open(inputfile,'r')
  file_content = f.read()
  f.close()

  # contruct output path, use the filename from the input file and the user specified output directory
  o = open(outputdir + "\\" + os.path.basename(os.path.realpath(inputfile)), "w")
  
  # if no speed was specified via command line, look for '; prime_speed_mm_per_s = [number]' matl token
  if speed == 0:
    m = re.search('; prime_speed_mm_per_s = (\\d+)', file_content)
    if m:
      try:
        speed = int(m.group(1))
      except:
        speed = 0
  
  if speed > 0:
    # find all destring prime blocks in the file, modify it via primeCallback and write it to the new destination
    o.write(re.sub("(?smi); 'Destring Prime'\\r?\\nG1 E\\d+ F(.*?)\\r?\\n", primeCallback, file_content, 999999999, re.MULTILINE))
  else:
    # no speed specified or matl tokens, write as is
    o.write(file_content)

  o.close()

if __name__ == "__main__":
  main(sys.argv[1:])