#script to pull data from the phadia100's .csv run files.

rm(list=ls())
#Set working directory
setwd("C:/Users/cew27/Dropbox (Personal)/R") #you can add in your own director here

data <- read.csv("IgE-20150115.csv", header=T, skip = 7, na.strings = "")

#seperate out the data we need and clean it up
#Note that if you're looking at the file in excel, the concentration appears under the column "(quot)", but when you read it into r, it's under "X.Conc.". I can't figure out why. Seems to be the case for other columns as well. Double-check that you're getting the data you want.
phadia <- data.frame(data$X.Request., data$X.Test., data$X.Conc., data$X.InsDil.)
colnames(phadia) <- c("sampleID", "test", "conc", "dil")

#Removes the junk leftover from the data summary at the bottom of the .csv and QC/CC data
phadia <- phadia[complete.cases(phadia),]

#make columns for study, subject #, and visit # (used to pick out which redcap doc to enter the values into)
phadia$study <- phadia$sampleID
phadia$study <- gsub("-.*", "", phadia$study)

phadia$subjectID <- phadia$sampleID
phadia$subjectID <- gsub(".*-", "", phadia$subjectID)
phadia$subjectID <- gsub("_.*", "", phadia$subjectID)

phadia$visitNum <- phadia$sampleID
phadia$visitNum <- gsub(".*_", "", phadia$visitNum)

#convert the concentration readings to numerics rather than factors.

phadia$conc <- as.numeric(as.character(phadia$conc))

#The raw data doesn't indicate if a concentration is off the scale, so we need to figure out which are extrapolated (>100 or < 0.1)

#change under-the-limit concentrations to "0"
v <- vector(mode="logical", length=0)
for (i in 1:length(phadia$conc)){
  v[i] <- (phadia$conc[i] < 0.1)
}   
phadia$conc[v] <- 0

#change over-the-limit concentrations to ">"
phadia$max <- phadia$dil*100

for (i in 1:length(phadia$max)){
  if (phadia$test[i] == "a-IgE") {phadia$max[i] = phadia$dil[i]*5000}
}

v <- vector(mode="logical", length=0)
for (i in 1:length(phadia$conc)){
  v[i] <- (phadia$conc[i] > phadia$max[i])
}   
phadia$conc[v] <- paste(">",phadia$max[v], sep="")

#Then we need to split the data by project and read the data into the appropriate redcap.
phad <- tapply(phadia, phadia$study)
