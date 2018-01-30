#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

###string rundir

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string group
#string checkStage
#string RMod
#string projectDir

${stage} ${RMod}
${checkStage}

set -x -e -o pipefail

echo "## "$(date)" ##  $0 Started "	
	
Rscript -e 'args <- commandArgs(trailingOnly = TRUE); sampledf=read.table(args[1], header=TRUE, na.string=c("","NA"), sep=","); sampledffilt=sampledf[which(sampledf$count >= 5000 ), ]; write.table(sampledffilt,file=stdout(),sep=",", row.names=FALSE, quote=FALSE, na="");' ${rundir}"/../*.input.csv  > "${rundir}/../samplesheet.filtered.csv"
#'args <- commandArgs(trailingOnly = TRUE); sampledf=read.table(args[1], header=TRUE, fill=NA,  sep=","); sampledffilt=sampledf[which(sampledf$count >= 5000 ), ]; write.table(sampledffilt,file=stdout(),sep=",", row.names=FALSE, quote=FALSE);' ${rundir}"/../*.input.csv  > "${rundir}/../samplesheet.filtered.csv"

  putFile "${rundir}"/../*.input.csv
	
echo "## "$(date)" ##  $0 Done "
