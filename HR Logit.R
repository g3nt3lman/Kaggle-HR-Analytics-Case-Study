rm(list=ls())

library(caret)
library(nnet)
library(paramtest)
library(lubridate)
library(data.table)

setwd("C:/Users/asus/Documents/R/other")
d=read.csv("general_data.csv", header=T, na.strings = c("NA"), sep="," )

boxplot(d$Age, main="Outliers check")
hist(d$Age, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$DistanceFromHome, main="Outliers check")
hist(d$DistanceFromHome, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$Education, main="Outliers check")
hist(d$Education, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$JobLevel, main="Outliers check")
hist(d$JobLevel, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$MonthlyIncome, main="Outliers check")
hist(d$MonthlyIncome, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$NumCompaniesWorked, main="Outliers check")
hist(d$NumCompaniesWorked, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$PercentSalaryHike, main="Outliers check")
hist(d$PercentSalaryHike, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$TotalWorkingYears, main="Outliers check")
hist(d$TotalWorkingYears, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$TrainingTimesLastYear, main="Outliers check")
hist(d$TrainingTimesLastYear, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$Age, main="Outliers check")
hist(d$Age, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$YearsAtCompany, main="Outliers check")
hist(d$YearsAtCompany, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$YearsSinceLastPromotion, main="Outliers check")
hist(d$YearsSinceLastPromotion, main="Outliers check", xlab=NA, ylab=NA)

boxplot(d$YearsWithCurrManager, main="Outliers check")
hist(d$YearsWithCurrManager, main="Outliers check", xlab=NA, ylab=NA)

d_e=read.csv("employee_survey_data.csv", header=T, na.strings = c("NA"), sep="," )
d_m=read.csv("manager_survey_data.csv", header=T, na.strings = c("NA"), sep="," )
d_time_in=read.csv("in_time.csv", header=T, na.strings = c("NA"), sep="," )
d_time_out=read.csv("out_time.csv", header=T, na.strings = c("NA"), sep="," )
emp_intime = as.data.frame(lapply( d_time_in[, -1], as.ITime))
emp_outtime = as.data.frame(lapply( d_time_out[, -1], as.ITime))
out_in = rowSums(is.na(d_time_in))
out_out = rowSums(is.na(d_time_out))


x = as.POSIXct("2017-05-17 01:00:00")
x = as.ITime(x)

change_time=function(enter){
  as.numeric(round(difftime(x, enter, 
           units = c("secs")),digits = 0))
}

emp_intime_int= as.data.frame(lapply( emp_intime, change_time))*-1
emp_outtime_int= as.data.frame(lapply( emp_outtime, change_time))*-1

emp_intime_int[sapply(emp_intime_int, function(x) all(is.na(x)))] = NULL
emp_outtime_int[sapply(emp_outtime_int, function(x) all(is.na(x)))] = NULL

emp_intime_int_avg = round(rowSums(emp_intime_int,na.rm = T)/ncol(emp_intime_int), digits=0)
emp_outtime_int_avg = round(rowSums(emp_outtime_int,na.rm = T)/ncol(emp_outtime_int), digits=0)

d_time_in = as.data.frame(cbind(d_time_in[,1],emp_intime_int_avg,out_in))
d_time_out = as.data.frame(cbind(d_time_out[,1],emp_outtime_int_avg))
d_time= merge(x=d_time_in, y=d_time_out, by.x ="V1", by.y ="V1")

d_e_m = merge(x=d_e, y=d_m, by.x ="EmployeeID", by.y ="EmployeeID")
d_g_e_m = merge(x=d_e_m, y=d, by.x ="EmployeeID", by.y ="EmployeeID")

data = merge(x=d_g_e_m, y=d_time, by.x ="EmployeeID", by.y ="V1")


##############################################
sum(colSums(is.na(data)))
indeksy=complete.cases(data)
d=data[indeksy,]

conv_to_dummy = function(factor, name){
  final_d = data.frame(factor)
  for (level in levels(final_d[,1])){
    final_d[, paste(name, level)] = as.integer(factor == level)
  }
  return(final_d)
}

#
d_attrition=conv_to_dummy(d$Attrition, "Attrition -")
d_attrition$factor=NULL
d$Attrition=NULL

#
d_business_travel=conv_to_dummy(d$BusinessTravel, "BusinessTravel -")
d_business_travel$factor=NULL
d$BusinessTravel=NULL
#
d_department=conv_to_dummy(d$Department, "Department -")
d_department$factor=NULL
d$Department=NULL
#
d_education=conv_to_dummy(d$EducationField, "EducationField -")
d_education$factor=NULL
d$EducationField=NULL
#
d_gender=conv_to_dummy(d$Gender, "Gender -")
d_gender$factor=NULL
d$Gender=NULL
#
d_jobRole=conv_to_dummy(d$JobRole, "JobRole -")
d_jobRole$factor=NULL
d$JobRole=NULL
#
d_martialStatus=conv_to_dummy(d$MaritalStatus, "MaritalStatus -")
d_martialStatus$factor=NULL
d$MaritalStatus=NULL
#
d_over18=conv_to_dummy(d$Over18, "Over18 -")
d_over18$factor=NULL
d$Over18=NULL

d$NumCompaniesWorked=as.integer(d$NumCompaniesWorked)
d$TotalWorkingYears=as.integer(d$TotalWorkingYears)

d$EmployeeCount=NULL
d$StandardHours=NULL
d$EmployeeID=NULL

d2=cbind(d_business_travel, d_department, d_education,
         d_gender, d_jobRole, d_martialStatus, d_over18)

d_non_cat = as.data.frame(scale(d, center = T, scale = TRUE))
y = d_attrition$`Attrition - Yes`

data=cbind(y,d_non_cat,d2)
data=as.data.frame(data)

##########################################################

fraction= floor(0.75 * nrow(data))

set.seed(123)
train_ind1 = sample(seq_len(nrow(data)), size = fraction)

d_train = data[train_ind1, ]
d_test = data[-train_ind1, ]

sum(colSums(is.na(d_test)))
sum((is.na(d_train)))

model = glm(y ~.,family=binomial(link='logit'),data=d_train)
BIC.logit = step(model, k = log(nrow(d_train)), trace = 0)
summary(BIC.logit)

fitted.results=predict(BIC.logit, newdata=d_test, type="response")
max(fitted.results)
fitted.results = ifelse(fitted.results > 0.15,1,0)
misClasificError = mean(fitted.results != d_test$d_y)
conf = confusionMatrix(factor(d_test$y), factor(fitted.results), positive = "1")
conf

#######################################################

th={}
spec={}
prec={}
acc={}
youden={}
j=1
for (i in seq(0.05, 0.9, by = 0.05)){
  fitted.results=predict(BIC.logit, newdata=d_test, type="response")
  fitted.results = ifelse(fitted.results > i,1,0)
  conf = confusionMatrix(factor(d_test$y), factor(fitted.results),positive = "1")
  conf$byClass[2]
  th[j]=i
  spec[j]=conf$byClass[2]
  prec[j]=conf$byClass[5]
  acc[j]=conf$overall[1]
  youden[j] = conf$byClass[3] + conf$byClass[4] - 1
  j=j+1
}

optim_results_reg=as.data.frame(cbind(th,spec,prec,acc, youden))
optim_results_reg[which.max(optim_results_reg$youden),]
plot(optim_results_reg$th, optim_results_reg$youden, type = "l", col ="blue",
     xlab="Threshold",
     ylab="J Youden factor")



