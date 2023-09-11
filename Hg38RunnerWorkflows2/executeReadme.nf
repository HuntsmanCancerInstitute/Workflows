#!/usr/bin/env nextflow

workflow {
    ExecuteReadMe()
}

process ExecuteReadMe {
  debug true
  
  output:
    stdout

  script:
    """
	echo Launching xxx.README.sh with Nextflow...
    	currDir=`pwd`
	echo \$currDir
	cd ${projectDir}
	./*.README.sh
	cp \$currDir/.command.log Logs/run.log
	echo Nextflow Complete!
    """
}


