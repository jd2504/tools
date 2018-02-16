library(ROCR)

cc <- read.csv("../input/UCI_Credit_Card.csv")

set.seed(1234)

x <- runif(nrow(cc))

ccTr <- cc[x >= 0.2,] # Training set
ccTe <- cc[x < 0.2,]  # Test set

rm(x) # good housekeeping

o <- 'default.payment.next.month' # setting the outcome variable
pos <- '1'

vars <- setdiff(colnames(cc), c('ID', o)) # variable names

# printing a few new lines to separate the output
cat('VARIABLE SUMMARY\n')
cat(paste(rep('-', 37), collapse = ''))
cat('\n')

varSumm <- function(df, vars){ # getting class information about a given variable
  for(v in vars){
    cat(sprintf("%s : %s   \tAnyNA : %s\n", v, 
                      class(unlist(df[,v])), anyNA(unlist(df[,v]))))
  }
}

varSumm(cc, vars) # getting summary information about all variables

# printing a few new lines to separate the output
cat('\n\n\n')

# Feature selection using AUROC

varModel <- function(outcome, predVar, testVar){
  # builds single variable models for feature selection.
  # outcome is the outcome variable, predVar is training set variable and testVar
  # is the test set variable
  if(range(predVar)[2] - range(predVar)[1] > 10){ # transforming numeric vars to categorical
    cuts <- unique(as.numeric(quantile(predVar, probs=seq(0, 1, 0.1), na.rm = TRUE)))
    varC <- cut(predVar, cuts, include.lowest = TRUE) # make sure to capture the 0's
    appC <- cut(testVar, cuts, include.lowest = TRUE)
  }
  else{
    varC <- predVar
    appC <- testVar
  }
  
  # using the categorical variables created above to generate a contingiency table
  vTab <- table(varC, outcome, useNA = 'ifany')

  
  # probability of randomly selecting a pos outcome from the training set
  # this is in case we encounter values in the test set that are not in the training set
  pPos <- sum(outcome)/length(unlist(outcome))
  
  # calculate the probability of randomly selecting a pos value conditioned on all levels
  pPosL <- (vTab[,pos]+1.0e-3*pPos)/(rowSums(vTab)+1.0e-3)
  
  # probability of selecting a positive given a value of NA if there are any
  pPosNA <- pPosL[which(is.na(labels(pPosL)))]
  
  # apply the model's "predictions" to the test data
  pred <- pPosL[as.character(appC)]
  
  # add predictions for NA values of the test var
  pred[is.na(testVar)] <- pPosNA
  
  # add pPos (line49) for unseen values in the test data
  pred[is.na(pred)] <- pPos
  
  # return the predictions
  pred
}

# log likelihood convenience function for evaluating variables
log.likelihood <- function(outcome, predVar){
  sum(ifelse(outcome == pos, log(predVar), log(1 - predVar)))
}

# AUROC convenience function
calcAUC <- function(outcome, predVar){ 
  perf <- performance(prediction(predVar, outcome==pos), 'auc')
  as.numeric(perf@y.values)
}


# printing a few new lines to separate the output
cat('SELECTED VARIABLES\n')
cat(paste(rep('-', 71), collapse = ''))
cat('\n')

# empty vector to be used below
pVars <- c()

# printing the variables whose training AUROC >= 0.55 and adding the variable names to the
# pVars vector
for(v in vars){
  
  # create a single variable model for each training variable
  theta.train <- varModel(ccTr[,o], ccTr[,v], ccTr[,v])
  
  # and do the same for the test variables
  theta.test <- varModel(ccTr[,o], ccTr[,v], ccTe[,v])
  
  # training set log likelihood
  LLtR <- log.likelihood(ccTr[,o], theta.train)
  
  # test set log likelihood
  LLtE <- log.likelihood(ccTe[,o], theta.test)
  
  # training set AUROC
  AUCtR <- calcAUC(ccTr[,o], theta.train)
  
  # test set AUROC
  AUCtE <- calcAUC(ccTe[,o], theta.test)
  
  if(AUCtR >= 0.55){
    # print the output
    cat(sprintf("%s\n", v))
    cat(sprintf("Training Log Likelihood : %4.3f\tTest Log Likelihood : %4.3f\n",
                LLtR, LLtE))
    cat(sprintf("Training AUROC : %4.3f\t\t\tTest AUROC : %4.3f",
                AUCtR, AUCtE))
    cat("\n\n")
    pVars <- c(pVars, v)
  }
  
}


# now that we have our variables, it's time to create the formula
formula <- paste(o, paste(pVars, collapse = ' + '), sep = ' ~ ')

# and finally time to build the model
fit <- glm(formula, family = binomial(link = 'logit'), data = ccTr)

# printing a few new lines to separate the output
cat('\n\nSUMMARY\n')
cat(paste(rep('-', 70), collapse = ''))
cat('\n')

# looking at the summary
print(summary(fit))

# printing a few new lines to separate the output
cat('\n\n')

# calculating predicted outcome on the test set
test.pred <- predict(fit, newdata = ccTe, type = 'response')

# calculating the log likelihood of the model
test.log.likelihood <- log.likelihood(ccTe[,o], test.pred)

# evaluating the model with the ROC
eval <- prediction(test.pred, ccTe[,o])

# calculating the AUROC
test.AUROC <- attributes(performance(eval, 'auc'))$y.values[[1]]

# plotting the ROC
plot(performance(eval, 'tpr', 'fpr'))

# setting a 0.5 threshold to see what we get
test.outcome <- ifelse(test.pred > 0.5, 1, 0)

# creating a confusion matrix for additional diagnostics
cM <- table(outcome=ccTe[,o], pred=test.outcome)

# calculating the accuracy, precision, recall and F1
accuracy <- sum(diag(cM))/sum(cM)
precision <- cM[2,2]/sum(cM[,2])
recall <- cM[2,2]/sum(cM[2,])
F1 <- (2 * precision * recall)/(precision+recall)

# printing some diagnostics
cat('DIAGNOSTICS\n')
cat(paste(rep('-', 34), collapse = ''))
cat('\n')

cat(sprintf("Accuracy : \t\t%4.3f\n", accuracy))
cat(sprintf("Precision : \t\t%4.3f\n", precision))
cat(sprintf("Recall : \t\t%4.3f\n", recall))
cat(sprintf("F1 : \t\t\t%4.3f\n", F1))
cat(sprintf("Log Likelihood : \t%4.3f\n", test.log.likelihood))
cat(sprintf("Mean Log Likelihood : \t%4.3f\n", (test.log.likelihood/nrow(ccTe))))
cat(sprintf("AUROC : \t\t%4.3f\n", test.AUROC))