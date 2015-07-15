# First cd to the directory with the *.sh and *.finished scripts
MOLGENIS_scriptsDir=$( cd -P "$( dirname "$0" )" && pwd )
echo "cd $MOLGENIS_scriptsDir"
cd $MOLGENIS_scriptsDir

# Use this to indicate that we skip a step
skip(){
	echo "0: Skipped --- TASK '$1' --- ON $(date +"%Y-%m-%d %T")" >> molgenis.skipped.log
}

# Skip this step if step finished already successfully
if [ -f CreatePaddedTargets_0.sh.finished ]; then
	skip CreatePaddedTargets_0.sh
	echo "Skipped CreatePaddedTargets_0.sh"
else
	echo "--- begin step: CreatePaddedTargets_0 ---"
	echo " "
	bash CreatePaddedTargets_0.sh
	echo " "
	echo "--- end step: CreatePaddedTargets_0 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f Fastqc_0.sh.finished ]; then
	skip Fastqc_0.sh
	echo "Skipped Fastqc_0.sh"
else
	echo "--- begin step: Fastqc_0 ---"
	echo " "
	bash Fastqc_0.sh
	echo " "
	echo "--- end step: Fastqc_0 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f Fastqc_1.sh.finished ]; then
	skip Fastqc_1.sh
	echo "Skipped Fastqc_1.sh"
else
	echo "--- begin step: Fastqc_1 ---"
	echo " "
	bash Fastqc_1.sh
	echo " "
	echo "--- end step: Fastqc_1 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f BwaMemAlignment_0.sh.finished ]; then
	skip BwaMemAlignment_0.sh
	echo "Skipped BwaMemAlignment_0.sh"
else
	echo "--- begin step: BwaMemAlignment_0 ---"
	echo " "
	bash BwaMemAlignment_0.sh
	echo " "
	echo "--- end step: BwaMemAlignment_0 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f BwaMemAlignment_1.sh.finished ]; then
	skip BwaMemAlignment_1.sh
	echo "Skipped BwaMemAlignment_1.sh"
else
	echo "--- begin step: BwaMemAlignment_1 ---"
	echo " "
	bash BwaMemAlignment_1.sh
	echo " "
	echo "--- end step: BwaMemAlignment_1 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f AddOrReplaceReadGroups_0.sh.finished ]; then
	skip AddOrReplaceReadGroups_0.sh
	echo "Skipped AddOrReplaceReadGroups_0.sh"
else
	echo "--- begin step: AddOrReplaceReadGroups_0 ---"
	echo " "
	bash AddOrReplaceReadGroups_0.sh
	echo " "
	echo "--- end step: AddOrReplaceReadGroups_0 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f AddOrReplaceReadGroups_1.sh.finished ]; then
	skip AddOrReplaceReadGroups_1.sh
	echo "Skipped AddOrReplaceReadGroups_1.sh"
else
	echo "--- begin step: AddOrReplaceReadGroups_1 ---"
	echo " "
	bash AddOrReplaceReadGroups_1.sh
	echo " "
	echo "--- end step: AddOrReplaceReadGroups_1 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f MergeBamFiles_0.sh.finished ]; then
	skip MergeBamFiles_0.sh
	echo "Skipped MergeBamFiles_0.sh"
else
	echo "--- begin step: MergeBamFiles_0 ---"
	echo " "
	bash MergeBamFiles_0.sh
	echo " "
	echo "--- end step: MergeBamFiles_0 ---"
	echo " "
	echo " "
fi
# Skip this step if step finished already successfully
if [ -f MergeBamFiles_1.sh.finished ]; then
	skip MergeBamFiles_1.sh
	echo "Skipped MergeBamFiles_1.sh"
else
	echo "--- begin step: MergeBamFiles_1 ---"
	echo " "
	bash MergeBamFiles_1.sh
	echo " "
	echo "--- end step: MergeBamFiles_1 ---"
	echo " "
	echo " "
fi
