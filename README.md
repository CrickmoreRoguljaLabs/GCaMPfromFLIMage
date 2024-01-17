# GCaMP-from-Flimage
GCaMP Analysis from FLIMage Software (for Windows, not tested on Mac). Depends on the padcat function.

# Summary:
This code takes the csv output from the FLIMage software and calculates the dF/F of channel 1 using the mean of a time period specified by the user.
ROI selection, intensity measurements, and background subtraction are all done within the FLIMage software, this code simply extracts the appropriate line from the csv file containing the sum of the intensity values and uses it to calculate the dF/F. The user may also choose to add in averaging or use a previously calculated dF/F value (such as in the case where two different csv files have the basline and experimental conditions). The output of this code is two .xlsx files saved to the same folder where the original csv files were saved. compiledRaw.xlsx contains the raw data while compiledDFF.xlsx contains the output dF/F with any averaging.

# About the output/fast mode
The code allows the user to batch analyze csv files exported from FLIMage. Each of the output files will contain the data from all the csv files, with each csv being represented by a different column. Running the code in fast mode allows users to omit assigning titles to these columns and subs in temp headings to all the columns, while choosing not to run in fast mode will allow the user to assign a column header corresponding to each csv for easy referencing later on. In either case where, the order of columns represents the order of the csv files in the original location.

If the user instead indicates they have a file with multiple ROIs, then batch analysis is not availble. Instead each column in the output files will correspond to a different ROI (in order).

# Instructions for use:
1. Open the code in Matlab
2. Run the code
3. In the command window of MATLAB the use will be asked if they are analyzing mutliple ROIs from a single file. 
4. The response from the user will prompt a user interface where the user can select the file to analyze. If the user indicated there was only one ROI, then they may select only one file. If the user indicated multiple ROIs then only one file may be selected and each column of the output files will represent a different ROI.
5. The user will be asked if they want to specify an Fo value. If they do not specify a value then they will be asked the frame rate of their data and how many seconds they want to use as the baseline. A frame rate look up table is provided in the command window with common rates used by our lab for convenience, you can add your own information to this window by editing the code between lines 102 and 103. Then they will be asked how many seconds they want to use for the baseline. The program converts this information into a number of frames to be used for baseline calculations.
6. The user will be asked if they want to average.
7. The user will be asked if they want to run in fast mode. if yes, the code will continue and finish. If no, the user will be show the name of each csv and be asked for input on the appropriate header for column in the excel file where that csv's output data will be stored. Then the code will continue and finish.
8. The code will cause the calculated Fo values to be displayed in the command window and will display 'Done!' when complete.

# Customization

To have the code extract a different row of data from the csv file to use for analysis change line 148 for the multiple ROI function or line 164 for single ROIs. Currently we use the data titled 'sumIntensity_bg-ROI1-ch1' which is in line 34 of the csv file for single ROI files.

To have the code use the median instead for the dF/F calculatation change line 231.
