#!/bin/sh

#
#
#Audio Cue goes here!!!
#Needed to know when to start the acquisition process
#


pkill gatttool
gcc -o Acquire_LowPass_Continuous Acquire_LowPass_Continuous.c -lm -lc -lliquid
#echo "Begin motion data input"
./Acquire_LowPass_Continuous 0.4 1
#echo "Begin Peak Find Portion"
sh find_all_waveform_peaks.sh motion_data_output.csv 100 150 300
#echo "Begin Normalization of peaks"
gcc -o correct_bubble_sort_norm correct_bubble_sort_norm.c
./correct_bubble_sort_norm waveform_peaks_output_x.csv x_playtest.csv waveform_peaks_output_z.csv z_playtest.csv
#echo "Begin Playtest Python Feature Discrimination"
python peakCounter.py
#echo "Finished with Python Portion"
#echo "Begin XCorr & AutoCorr Section"



####################################################
##############Begin XCORR CALCULATIONS##############
####################################################
sh all_compute_cross_correlation.sh 
#echo "Finished with Xcorr & Autocorr Calculations"
gcc -o 1ZZ_peak_find 1ZZ_peak_find.c -lm
#echo "Begin searching for XXPeaks"
sh find_XX_peaks.sh xcorr_output.csv 5000000 
#echo "End Searching for XXPeaks"
gcc -o feature_compute_autocorrelation_s feature_compute_autocorrelation_s.c
#echo "Begin counting # of XXPeaks"
./feature_compute_autocorrelation_s waveform_peaks_output_XX.csv DataFile.txt
#echo "End count of XX Peaks"


cat DataFile.txt
#echo "Parse DataFile.txt begins"
python DataParser.py
#echo "Print out Test File values: "
cat TestFile.txt

#echo "Begin Moion Recognition FANN execution"
gcc -I ../src/include -L ../src/ -O3 MotionRecog_and_xor_recognition.c -o Motion_FANN_Recognition -lfann -lm
cat TrainingFile.txt
./Motion_FANN_Recognition

while true; do
	read -p "Was the motion correctly recognized?" yn
	case $yn in
		[Yy]* ) cat TrainingFile.txt;
			python Add2TrainingData.py;
			cat TrainingFile.txt;
			echo "Doing things";
			gcc -I ../src/include -L ../src/ -O3 modified_and_xor_train.c -o modified_and_xor_train -lfann -lm;
			./modified_and_xor_train;
			break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	esac
done
