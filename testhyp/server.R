##########################################################################
## testhyp Shiny/R app server.R                                         ##
##                                                                      ##
## Author Grégoire Vincke http://www.uclouvain.be/gregoire.vincke       ##
## For Statistical eLearning Tools http://sites.uclouvain.be/selt/      ##
##                                                                      ##
## Licences : CC-BY for http://sites.uclouvain.be/selt/shiny/testhyp    ##
##            GPL for source code on http://github.com                  ##
##########################################################################

  #initiate global counters
  SP<-list()
  SP$rho<-0
  SP$nrho<-0
  SP$N<-0
  SP$lpcrho<-list()
  SP$lnrho<-list()
  
  # Initiation of colors : Red, Green, Blue, Alpha) All parameters are from 0 (none) to 1 (full). Alpha mean opacity : from 0 (transparent) to 1 (opacity)
  col.alpha<-rgb(1,0,0,0.5)#col.alpha<-rgb(0.98,0.45,0.45,0.25)
  col.beta<-rgb(1,0,0,0.5)#col.beta<-rgb(0.98,0.45,0.45,0.25)
  col.confidence<-rgb(0,0.7,0,0.5)#col.confidence<-rgb(0.45,0.98,0.45,0.25)
  col.power<-rgb(0,0.7,0,0.5)#col.power<-rgb(0.45,0.98,0.45,0.25)

shinyServer(function(input, output) {

  # Create a reactiveValues object, to let us use settable reactive values
  rv <- reactiveValues()
  # To start out, lastAction == NULL, meaning nothing clicked yet
  rv$lastAction <- 'none'
  # An observe block for each button, to record that the action happened
  observe({
    if (input$takeech != 0) {
      rv$lastAction <- 'takeech'
    }
  })
  observe({
    if (input$reset != 0) {
      rv$lastAction <- 'reset'
    }
  })
  
  getech<-reactive({#create a sample of n values from N(0;1) when input$takeech is set (when the takeech button is pressed)
    if(input$takeech == 0)
      return(NULL)#don't do anything until after the first button is pushed
      return(isolate({
	rnorm(input$n)#create a sample of n values from N(0;1)
      }))
  })
  
  getInputValues<-reactive({
    v<-list()
    v<-input #the input variable is a list of all values defined in the user interface form
    return(v)
  })
  
  getComputedValues<-reactive({
    cv<-list()#created empty computed values list
    v<-getInputValues() # get all values of input list
    
    ## Computation of means, standard-deviations, variance of H0, H1, and Reality distributions ##
    # Definition of mean of H1 in function of the model which is considered as true
    if(v$truehyp=="h1"){
      cv$mx1<-v$mx1 #If H1 is true, µ1 has to be set to the mx1 sended var
     }
    if(v$truehyp=="h0"){
      cv$mx1<-v$mx0 #If H0 is true, µ1 has to be set to the mx0 sended var
    }
    
    cv$vx<-v$sx^2 #variance of x (Reality)
    cv$vx.dech<-cv$vx/v$n #variance of the sample distribution of x (dech = distribution d'échantillonnage) 
    cv$sx.dech<-sqrt(cv$vx.dech) #standard-deviation of the sample distribution of x (dech = distribution d'échantillonnage)
    cv$sx0<-v$sx/sqrt(v$n)#standard-deviatione of H0
    cv$vx0<-(cv$sx0)^2 #variance of H0
    cv$sx1<-v$sx/sqrt(v$n) #standard-deviation of H1
    
    #Computation of the maximum density between H0 and H1 : used to set the same y axis limits on the plots
    cv$dmxr<-dnorm(v$mx1,mean=v$mx1,sd=v$sx)#density of the mean of Reality (compute on mx1 but should be tehe same for mx0 in N(mx0,sx)
    cv$dmx0<-dnorm(v$mx0,mean=v$mx0,sd=cv$sx0)#density of the mean of H0
    cv$dmx1<-dnorm(cv$mx1,mean=cv$mx1,sd=cv$sx1)#density of the mean of H1
    cv$maxdmx<-max(cv$dmx0,cv$dmx1)#Maximum of the both
    if(v$freezeyaxis){#if whe decided to freeze the axis, the max density will be 0.2 (correspond to the density of mean of N(0,1)
      cv$maxdmx<-0.2
    }
    cv$yaxislim<-cv$maxdmx+(cv$maxdmx*0.2)#the limit of the y axis of the plots is the max density increased of 20% to allow the axis not to touche each others
    
    ## Computation of coordinates for plotting distributions (polygones)  ##
    z<-seq(-5,5,length=100) #Create 100 values between -5 and 5, the Z(0,1) minimum and maximum values to consider
    cv$xr<-(z*v$sx)+cv$mx1 #X coordinates for Reality distribution
    cv$x0<-(z*cv$sx0)+v$mx0 #X coordinates for H0 distribution
    cv$x1<-(z*cv$sx1)+cv$mx1#X coordinates for H1 distribution
    cv$yr<-dnorm(cv$xr,mean=cv$mx1,sd=v$sx) #Y coordinates for Reality distribution
    cv$y0<-dnorm(cv$x0,mean=v$mx0,sd=cv$sx0)#Y coordinates for H1 distribution
    cv$y1<-dnorm(cv$x1,mean=cv$mx1,sd=cv$sx1)#Y coordinates for H2 distribution
    
    ## Computation of alpha, beta, confidence and power related variables  ##
    cv$alpha<-round(1-v$confidence,3)#Computation of alpha probability
    cv$alpha.z<-round(qnorm(v$confidence),3)#Z value corresponding to alpha probability
    cv$alpha.x<-(cv$alpha.z*cv$sx0)+v$mx0#X coordinate of alpha probability quantile in H0
    cv$alpha.y<-dnorm(cv$alpha.x, mean=v$mx0, sd=cv$sx0)#Y coordinate of alpha probabiltity quantile in H0
    
    cv$alpha.z.polygon<-seq(cv$alpha.z,5,length=100)#Z values for ploting alpha probability polygon in H0
    cv$alpha.x.polygon<-(cv$alpha.z.polygon*cv$sx0)+v$mx0#X coordinates for ploting alpha probability polygon in H0
    cv$alpha.y.polygon<-dnorm(cv$alpha.x.polygon,mean=v$mx0,sd=cv$sx0)#Y coordinates for ploting alpha probability polygon in H0
    
    cv$confidence.z.polygon<-seq(-5,cv$alpha.z,length=100)#Z values for ploting confidence probability polygon in H0
    cv$confidence.x.polygon<-(cv$confidence.z.polygon*cv$sx0)+v$mx0#X coordinates for ploting confidence probability polygon in H0
    cv$confidence.y.polygon<-dnorm(cv$confidence.x.polygon,mean=v$mx0,sd=cv$sx0)#Y coordinates for ploting confidence probability polygon in H0
    
    cv$beta.y<-dnorm(cv$alpha.x, mean=cv$mx1, sd=cv$sx1)#y coordinates for beta probability quantile in H1
    cv$beta.z<-(cv$alpha.x-cv$mx1)/cv$sx1#z value in H1 corresponding to beta probability
    cv$beta<-pnorm(cv$beta.z)# beta probability
    cv$beta.z.polygon<-seq(-5,cv$beta.z,length=100)#Z values for ploting beta probability polygon in H1
    cv$beta.x.polygon<-(cv$beta.z.polygon*cv$sx1)+cv$mx1#X coordinates for ploting beta probability polygon in H
    cv$beta.y.polygon<-dnorm(cv$beta.x.polygon,mean=cv$mx1,sd=cv$sx1)#Y coordinates for ploting beta probability polygon in H
    
    cv$power<-1-cv$beta #computation of power
    cv$power.z.polygon<-seq(cv$beta.z,5,length=100)#Z values for ploting power probability polygon in H1
    cv$power.x.polygon<-(cv$power.z.polygon*cv$sx1)+cv$mx1#X values for ploting power probability polygon in H1
    cv$power.y.polygon<-dnorm(cv$power.x.polygon,mean=cv$mx1,sd=cv$sx1)#Y values for ploting power probability polygon in H1
    cv$power.d<-abs(cv$mx1-v$mx0)/v$sx #power d=|µ1-µ2|/sigma
    #x values for the power curve adapted to d and n (x=d, y=power)
    if(cv$power.d <= 2.5){#d max value setted to 2.5
      cv$power.curve.x<-seq(0,2.5,0.01)
    } else {#x max value setted to cv$power.d
      cv$power.curve.x<-seq(0,cv$power.d,0.01)
    }
    cv$power.curve.x.lim<-max(cv$power.curve.x)#limit of x values for the power curve adapted to d and n (x=d, y=power)
    cv$power.curve.y<-1-pnorm(cv$alpha.z-cv$power.curve.x*sqrt(v$n))#y values for the power curve adapted to d and n (x=d, y=power)
    
    ## Computation of sample related values ##
    cv$ech.z<-getech()#create n stochastic values form N(0;1) when input$takeech is implemented (when "takeech" button is pressed)
    if (rv$lastAction=='reset') {# If "reset" button has been pressed, reset all session values to NULL, or 0
      cv$ech.z<-NULL
      SP$rho<<-0
      SP$nrho<<-0
      SP$N<<-0
      SP$lpcrho<<-list()
      SP$lnrho<<-list()
    }
    cv$ech.exist<-length(cv$ech.z)#mesure length of sample values to test if a sample has been created
    if(v$truehyp=="h1"){#if H1 is considered as the true model
      cv$ech.x<-(cv$ech.z*v$sx)+cv$mx1#Then sample values are compute with H1 mean and standard deviation
    }
    if(v$truehyp=="h0"){#if H0 is considered as the true model
      cv$ech.x<-(cv$ech.z*v$sx)+v$mx0#Then sample values are compute with H0 mean and standard deviation
    }
    
    if(cv$ech.exist){#If there is a sample, then compute sample related values
      cv$ech.m<-mean(cv$ech.x)#mean of sample
      cv$ech.s<-sd(cv$ech.x)#standard deviation of sample
      cv$ech.m.z0<-(cv$ech.m-v$mx0)/cv$sx0#Z value corresponding to mean of sample in H0
      cv$ech.m.pvalue<-signif(1-pnorm(cv$ech.m.z0),2)#p-value of the mean of sample in H0
      if(cv$ech.m.pvalue<0.001){#Test to avoid less than 3 digits p-values
	cv$ech.m.pvalue.text<-" <0.001"
      } else {
	cv$ech.m.pvalue.text<-cv$ech.m.pvalue
      }
      cv$ech.y<-seq(0.45,0.45,length=cv$ech.exist)#y coordinates of sample values
      if(cv$ech.exist && v$showpvaluearea){#trace the p-value polygon if a sample exist and the plot of p-value is asked
	cv$ech.m.pvalue.z.polygon<-seq(cv$ech.m.z0,5,length=100)#compute z coordinates for plotting the p-value
	cv$ech.m.pvalue.x.polygon<-(cv$ech.m.pvalue.z.polygon*cv$sx0)+v$mx0#compute x coordinates for p-value polygon plotting
	cv$ech.m.pvalue.y.polygon<-dnorm(cv$ech.m.pvalue.x.polygon,mean=v$mx0,sd=cv$sx0)#compute the y coordinates for p-value polygon plotting
      }
    }
    ## Computation of confidence intervals for the mean µ ##    
    cv$ic.z<-qnorm(1-cv$alpha/2)#z positive limit of a bidirectionnal confidence interval in N(0,1) => for CI with known variance
    cv$ic.t<-qt(1-cv$alpha/2,v$n-1)#t positive limit of a bidirectionnal confidence interval in t(n-1) => for CI with unknown variance
    cv$ic.z.limit.inf<-mean(cv$ech.x)-cv$ic.z*cv$sx.dech#compute the CI lower limit when variance known
    cv$ic.z.limit.sup<-mean(cv$ech.x)+cv$ic.z*cv$sx.dech#compute the CI higher limit when variance known
    cv$ic.t.limit.inf<-mean(cv$ech.x)-cv$ic.t*(cv$ech.s/sqrt(v$n))#compute the CI lower limit when variance unknown
    cv$ic.t.limit.sup<-mean(cv$ech.x)+cv$ic.t*(cv$ech.s/sqrt(v$n))#compute the CI higher limit when variance unknown
    
    ## Testing sample against H0 ##
    if(cv$ech.exist && rv$lastAction=='takeech'){
      if(cv$ech.m >= cv$alpha.x){#when mean of sample is inside the alpha region => reject of H0 hypothesis (RH0)
	  SP$rho<<-SP$rho+1#Add 1 to number of rejects of H0
	} else {#when mean of sample is outside the alpha region => non reject of H0 (NRH0)
	  SP$nrho<<-SP$nrho+1#add one to number of non reject of H0
	}
      SP$N<<-SP$rho+SP$nrho#Compute total number of tests
      SP$lnrho<<-c(SP$lnrho,list(SP$N))#update list of number of tests : will be used as x coordinates for % of RH0
      SP$rhopc<<-round(SP$rho/(SP$N),2) #Compute percentage of reject of H0
      SP$lpcrho<<-c(SP$lpcrho,list(SP$rhopc)) #Add actual %RH0 to the list
     }
    return(cv)# Return all computed values list
  })

  
  output$doubleplot <- renderPlot({
    v<-getInputValues()#Get all values from inputs
    cv<-getComputedValues()#Get all values computed from input values
    nplot<-3#Default number of plots
    if(v$showrhotrend){nplot<-nplot+1}#Add 1 to number of plots when trend of %RH0 is asked
    if(v$showpowertrend){nplot<-nplot+1}#Add one to number of plots when trend of power is asked
    if(v$hideh1){nplot<-nplot-1}#Minus one to number of plots when Hiding H1 plot is asked 
    par(mfrow=c(nplot,1))#Set plots as lines of a single plots
    ##################
    ## Plot Reality ##
    ##################
    par(mai=c(0,1,0,1),bty="n")#graphical parameters:
    #mai : set margins : bottom, left, top, right
    #bty : A character string which determined the type of box which is drawn about plots. If bty is one of "o" (the default), "l", "7", "c", "u", or "]" the resulting box resembles the corresponding upper case letter. A value of "n" suppresses the box.
    plot(cv$xr,cv$yr,type="l",lty=1,lwd=1,col="black",yaxt="n",las=1,xaxs="i",yaxs="i",cex.lab=1,cex.axis=1,xlim=c(0,100),ylim=c(0,cv$yaxislim),ylab="density",xlab="",xaxp=c(0,100,20)) #plot x and x reality coordinates
    #type='l' : line type of plot
    #lty : line type : 1 = solid, 2 = dotted, etc
    #lwd : line waight : 1=default
    #col : color
    #yaxt="n" = do not draw y axis => it will be defined in the axis()function
    #las=
    #xaxs : 
    #yaxs : 
    #cex.lab : size of labels
    #cex.axis : size of axis values
    #xlim : define the limits of the x axis
    #ylim : define the limits of y axis
    #ylab : define label of y axis
    #xlab : define label of x axis
    #xaxp : define values for x axis
    axis(2,las=2,yaxp=c(0,signif(cv$maxdmx,1),4))#define the y axis 
    #las : define the border where to put axis : 1 =bottom, 2=left, 3=top, 4=right
    ## Texts and lines inside plot ##
    #bquote is used when text include a mathematical expression, or a computed value
    text(1,signif(cv$maxdmx,1)*1.1,labels="Modeles",cex=2,pos=4)
    text(99,signif(cv$maxdmx,1)*1.1,labels="Observations",cex=2,pos=2)
    text(1,signif(cv$maxdmx,1)*0.9,labels="Realite",cex=2, pos=4)
    text(1,signif(cv$maxdmx,1)*0.7,labels=bquote(N *"~"* ( mu[1] *","* sigma^2 )),cex=1.5,pos=4)
    text(1,signif(cv$maxdmx,1)*0.5,labels=bquote(N *"~"* (.(cv$mx1)*","*.(cv$vx))),cex=1.5,pos=4)
    if(v$showmu){#if mean as to be shown
	if(v$truehyp=="h1"){#if H1 is true
	  lines(x<-c(v$mx1,v$mx1),y <- c(0,cv$dmxr*0.45),lty=3)
	  text(v$mx1,cv$dmxr*0.5,labels=expression(mu[1]),cex=1.5)
	  lines(x<-c(v$mx1,v$mx1),y <- c(cv$dmxr*0.55,cv$dmxr),lty=3)
	}
	if(v$truehyp=="h0"){#if H0 is true
	  lines(x<-c(v$mx0,v$mx0),y <- c(0,cv$dmxr*0.45),lty=3)
	  text(v$mx0,cv$dmxr*0.5,labels=expression(mu[0]),cex=1.5)
	  lines(x<-c(v$mx0,v$mx0),y <- c(cv$dmxr*0.55,cv$dmxr),lty=3)
	}
     }
    if(cv$ech.exist){#if a sample exist
      points(cv$ech.x,cv$ech.y*0.01,pch=23,cex=2)#Add points to the plot
      rug(cv$ech.x,lwd=2)#plot values close to x axis
      # Some texts
      text(99,signif(cv$maxdmx,1)*0.9,labels=bquote(n == .(round(v$n,2))),cex=1.5,pos=2)
      text(99,signif(cv$maxdmx,1)*0.7,labels=bquote(bar(x) == .(round(cv$ech.m,2))),cex=1.5,pos=2)
      text(99,signif(cv$maxdmx,1)*0.5,labels=bquote(s^2 == .(round(cv$ech.s,2))),cex=1.5,pos=2)
      if(v$showboxplot){#if boxplot have to be shown
	boxplot(cv$ech.x,horizontal = TRUE,add = TRUE,at = signif(cv$maxdmx,1)*0.2, boxwex = signif(cv$maxdmx,1)*0.2, xaxt="n", yaxt="n")#Add boxplot to the plot
      }
      if(v$showmean){#If mean has to be shown
	text(cv$ech.m,signif(cv$maxdmx,1)*0.7,labels=expression(bar(x)),cex=2)#,pos=0
	lines(x<-c(cv$ech.m,cv$ech.m),y <- c(-0.01,signif(cv$maxdmx,1)*0.7),lty=5,lwd=1)
      }
      if(v$showicz){#if CI for µ with known variance has to be shown
	text(99,signif(cv$maxdmx,1)*0.3,labels=bquote(paste("IC",.(v$confidence*100)," pour ",sigma^2," connue : [",.(round(cv$ic.z.limit.inf,2)),";",.(round(cv$ic.z.limit.sup,2)),"]",sep="")),cex=1.5,pos=2)
	lines(x<-c(cv$ic.z.limit.inf,cv$ic.z.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	lines(x<-c(cv$ic.z.limit.sup,cv$ic.z.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
      }
      if(v$showict){#if CI for µ with known unvariance has to be shown
	text(99,signif(cv$maxdmx,1)*0.1,labels=bquote(paste("IC",.(v$confidence*100)," pour ",sigma^2," inconnue : [",.(round(cv$ic.t.limit.inf,2)),";",.(round(cv$ic.t.limit.sup,2)),"]",sep="")),cex=1.5,pos=2)
	lines(x<-c(cv$ic.t.limit.inf,cv$ic.t.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	lines(x<-c(cv$ic.t.limit.sup,cv$ic.t.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
      } 
    }
    
    #############
    ## Plot H1 ##
    #############
    if(!v$hideh1) {
      par(mai=c(0,1,0,1))
      plot(cv$x1,cv$y1,type="l",lwd=1,col="black",yaxt="n",bty="n",las=1,xaxs="i",yaxs="i",cex.lab=1,cex.axis=1,xlim=c(0,100),ylim=c(0,cv$yaxislim),ylab="density",xlab="",xaxp=c(0,100,20)) #See plot of reality for parameters explanataions
      axis(2,las=2,yaxp=c(0,signif(cv$maxdmx,1),4))#Y axis
      ## Texts inside the plot
      text(1,signif(cv$maxdmx,1)*0.9,labels=bquote(H[1]),cex=2,pos=4)
      text(1,signif(cv$maxdmx,1)*0.7,labels=bquote(N *"~"* ( mu[1] *","* frac(sigma^2,n) )),cex=1.5,pos=4)#paste("N~(",mx1,",",round(x.var,2),")",sep="")
      text(1,signif(cv$maxdmx,1)*0.5,labels=bquote(N *"~"* (.(cv$mx1)*","*.(round(cv$vx.dech,2)))),cex=1.5,pos=4)#text(1,signif(cv$maxdmx,1)*0.8,labels=paste("H1 N~(",mx1,",",round(cv$vx.dech,2),")",sep=""),cex=2,pos=4)
      text(1,signif(cv$maxdmx,1)*0.3,labels=bquote(beta == .(signif(cv$beta,2))),cex=1.5,pos=4)
      text(1,signif(cv$maxdmx,1)*0.1,labels=bquote(1 - beta == .(signif(cv$power,2))),cex=1.5,pos=4)
      if(v$showbetaarea){#If beta area has to be shown
	polygon(c(cv$beta.x.polygon,cv$alpha.x),c(cv$beta.y.polygon,0),col=col.beta)#,density=15,angle=45)
      }
      if(v$showpowerarea){#If power area has to be shown
	polygon(c(cv$alpha.x,cv$power.x.polygon),c(0,cv$power.y.polygon),col=col.power)#,density=15,angle=45)
      }
      lines(x<-c(cv$alpha.x,cv$alpha.x),y <- c(0,cv$beta.y),lty=1)
      if(v$alphabetalabels){#Show labels (text) if needed
	text(cv$alpha.x-0.5,cv$yaxislim*0.05,labels=expression(beta),cex=1.5,pos=2)
	text(cv$alpha.x+0.5,cv$yaxislim*0.05,labels=expression(1-beta),cex=1.5,pos=4)
      }
      if(v$showmu1){#Show µ1 if needed
	lines(x<-c(cv$mx1,cv$mx1),y <- c(0,cv$dmx1*0.45),lty=3)
	text(cv$mx1,cv$dmx1*0.5,labels=expression(mu[1]),cex=1.5)
	lines(x<-c(cv$mx1,cv$mx1),y <- c(cv$dmx1*0.55,cv$dmx1),lty=3)
      }
      if(cv$ech.exist){#if sampl exist
	if(v$showmean){#If show mean
	  lines(x<-c(cv$ech.m,cv$ech.m),y <- c(0,dnorm(0)+0.2),lty=5,lwd=1)
	}
	if(v$showicz){#If CI for known variance has to be shown
	  lines(x<-c(cv$ic.z.limit.inf,cv$ic.z.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	  lines(x<-c(cv$ic.z.limit.sup,cv$ic.z.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	}
	if(v$showict){#If CI for unknown variance has to be shown
	  lines(x<-c(cv$ic.t.limit.inf,cv$ic.t.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	  lines(x<-c(cv$ic.t.limit.sup,cv$ic.t.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	}
      }
    }

    #############
    ## Plot H0 ##
    #############
    par(mai=c(0,1,0,1))
    plot(cv$x0,cv$y0,type="l",lwd=1,col="black",yaxt="n",bty="n",las=1,xaxs="i",yaxs="i",cex.lab=1,cex.axis=1,xlim=c(0,100),ylim=c(0,cv$yaxislim),ylab="density",xlab="",xaxp=c(0,100,20)) #See plot of reality for parameters explanataions
    axis(2,las=2,yaxp=c(0,signif(cv$maxdmx,1),4))#Y axis
    ## Seme text and lines ##
    text(1,signif(cv$maxdmx,1)*0.9,labels=bquote(H[0]),cex=2,pos=4)
    text(1,signif(cv$maxdmx,1)*0.7,labels=bquote(N *"~"* ( mu[0] *","* frac(sigma^2,n) )),cex=1.5,pos=4)#paste("N~(",mx1,",",round(x.var,2),")",sep="")
    text(1,signif(cv$maxdmx,1)*0.5,labels=bquote(N *"~"* (.(v$mx0)*","*.(round(cv$vx0,2)))),cex=1.5,pos=4)#text(1,signif(cv$maxdmx,1)*0.8,labels=paste("H0 N~(",mx0,",",round(cv$vx0,2),")",sep=""),cex=2,pos=4)
    text(1,signif(cv$maxdmx,1)*0.1,labels=bquote(alpha == .(cv$alpha)),cex=1.5,pos=4)
    text(1,signif(cv$maxdmx,1)*0.3,labels=bquote(1 - alpha == .(v$confidence)),cex=1.5,pos=4)
    if(v$h1overh0){
      polygon(c(cv$alpha.x,cv$x1),c(0,cv$y1))
      if(v$showbetaarea){
	polygon(c(cv$beta.x.polygon,cv$alpha.x),c(cv$beta.y.polygon,0),col=col.beta)#,density=15,angle=45)
      }
      if(v$showpowerarea){
	polygon(c(cv$alpha.x,cv$power.x.polygon),c(0,cv$power.y.polygon),col=col.power)#,density=15,angle=45)
      }
      lines(x<-c(cv$alpha.x,cv$alpha.x),y <- c(0,cv$beta.y),lty=1)
      if(v$showmu1){
	lines(x<-c(cv$mx1,cv$mx1),y <- c(0,cv$dmx1*0.45),lty=3)
	text(cv$mx1,cv$dmx1*0.5,labels=expression(mu[1]),cex=1.5)
	lines(x<-c(cv$mx1,cv$mx1),y <- c(cv$dmx1*0.55,cv$dmx1),lty=3)
      }
      text(10,signif(cv$maxdmx,1)*0.9,labels=bquote(H[1]),cex=2,pos=4)
      text(10,signif(cv$maxdmx,1)*0.7,labels=bquote(N *"~"* ( mu[1] *","* frac(sigma^2,n) )),cex=1.5,pos=4)#paste("N~(",mx1,",",round(x.var,2),")",sep="")
      text(10,signif(cv$maxdmx,1)*0.5,labels=bquote(N *"~"* (.(cv$mx1)*","*.(round(cv$vx.dech,2)))),cex=1.5,pos=4)#text(1,signif(cv$maxdmx,1)*0.8,labels=paste("H1 N~(",mx1,",",round(cv$vx.dech,2),")",sep=""),cex=2,pos=4)
      text(10,signif(cv$maxdmx,1)*0.3,labels=bquote(beta == .(signif(cv$beta,2))),cex=1.5,pos=4)
      text(10,signif(cv$maxdmx,1)*0.1,labels=bquote(1 - beta == .(signif(cv$power,2))),cex=1.5,pos=4)
    }
    if(v$showalphaarea || v$showconfidencearea){
      if(v$showalphaarea){
	polygon(c(cv$alpha.x,cv$alpha.x.polygon),c(0,cv$alpha.y.polygon),col=col.alpha)#,density=15,angle=135)
      }
      if(v$showconfidencearea){
	polygon(c(cv$alpha.x,cv$confidence.x.polygon),c(0,cv$confidence.y.polygon),col=col.confidence)#,density=15,angle=135)
      }
    } else {
      lines(x<-c(cv$alpha.x,cv$alpha.x),y <- c(-0.1,cv$alpha.y),lty=1)
    }
    if(cv$ech.exist && v$showpvaluearea){
      polygon(c(cv$ech.m,cv$ech.m.pvalue.x.polygon),c(0,cv$ech.m.pvalue.y.polygon),density=c(30),angle=135)
    }
    if(v$alphabetalabels){
      text(cv$alpha.x-0.5,cv$yaxislim*0.05,labels=expression(1-alpha),cex=1.5,pos=2)
      text(cv$alpha.x+0.5,cv$yaxislim*0.05,labels=expression(alpha),cex=1.5,pos=4)
    }
    if(v$showmu0){
      lines(x<-c(v$mx0,v$mx0),y <- c(0,cv$dmx0*0.45),lty=3)
      text(v$mx0,cv$dmx0*0.5,labels=expression(mu[0]),cex=1.5)
      lines(x<-c(v$mx0,v$mx0),y <- c(cv$dmx0*0.55,cv$dmx0),lty=3)
    }
    if(cv$ech.exist){
      if(v$showmean){
	lines(x<-c(cv$ech.m,cv$ech.m),y <- c(0,dnorm(0)+0.2),lty=5,lwd=1)
	}
      if(v$showicz){
	lines(x<-c(cv$ic.z.limit.inf,cv$ic.z.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	lines(x<-c(cv$ic.z.limit.sup,cv$ic.z.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
      }
      if(v$showict){
	lines(x<-c(cv$ic.t.limit.inf,cv$ic.t.limit.inf),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
	lines(x<-c(cv$ic.t.limit.sup,cv$ic.t.limit.sup),y <- c(-0.01,dnorm(0)+0.2),lty=3,lwd=1)
      }
      text(99,signif(cv$maxdmx,1)*0.9,labels=bquote(bar(x) == .(round(cv$ech.m,2))),cex=1.5,pos=2)
      text(99,signif(cv$maxdmx,1)*0.7,labels=paste("p-valeur : ",cv$ech.m.pvalue.text,sep=""),cex=1.5,pos=2)
      if(cv$ech.m >= cv$alpha.x){
	text(99,signif(cv$maxdmx,1)*0.5,labels=bquote(paste("Conclusion : ",RH[0],sep="")),cex=1.5,pos=2)
      } else {
	text(99,signif(cv$maxdmx,1)*0.5,labels=bquote(paste("Conclusion : ",NRH[0],sep="")),cex=1.5,pos=2)
      }
      text(99,signif(cv$maxdmx,1)*0.2,labels=bquote(paste("%",RH[0]," = ",frac(.(SP$rho),.(SP$N))," = ",.(SP$rhopc),sep="")),cex=1.5,pos=2)# paste("%RH0 :",SP$rhopc,sep="")
    }

    ###############
    ## Plot %RH0 ##
    ###############

    if(v$showrhotrend){
      if(cv$ech.exist){
      #IF there is less than 20 samples, set the x axis limit to 20. Else set it to number of samples
	if(SP$N<20){
	  nrholim<-20
	} else {
	  nrholim<-SP$N
	}
	nrho<-SP$lnrho
	pcrho<-SP$lpcrho
      } else {
	nrholim<-20
	nrho<-c(1)
	pcrho<-c(0)
      }
      par(mai=c(0.25,1,0,1))
      plot(nrho,pcrho,type="l",lwd=1,col="black",yaxt="n",bty="n",las=1,xaxs="i",yaxs="i",cex.lab=1,cex.axis=1,ylim=c(0,1.3),ylab=bquote(paste("%",RH[0],sep="")),xlab="",xaxp=c(0,nrholim,nrholim),xlim=c(0,nrholim))#See plot of reality for parameters explanataions
      axis(2,las=2,yaxp=c(0,1,2))
      lines(x<-c(0,nrholim),y <- c(cv$power,cv$power),lty=3)
      text(1,cv$power*1.05,expression(1-beta),pos=4)
    }
    
    ###############
    ## Plot power ##
    ###############
    if(v$showpowertrend){
      par(mai=c(0.5,1,0,1))
      plot(cv$power.curve.x,cv$power.curve.y,type="l",lwd=1,col="black",yaxt="n",bty="n",las=1,xaxs="i",yaxs="i",cex.lab=1,cex.axis=1,ylim=c(0,1.3),ylab=bquote(1-beta),xlab=bquote(d == frac(paste("|",mu[1]-mu[0],"|",sep=""),sigma)),xaxp=c(0,cv$power.curve.x.lim,cv$power.curve.x.lim/0.5),xlim=c(0,cv$power.curve.x.lim))#See plot of reality for parameters explanataions
      axis(2,las=2,yaxp=c(0,1,2))
      lines(x<-c(cv$power.d,cv$power.d),y <- c(0,cv$power),lty=3)
      lines(x<-c(0,cv$power.d),y <- c(cv$power,cv$power),lty=3)
      lines(x<-c(1,1),y <- c(0.5,0.5))
      lines(x<-c(0,cv$power.curve.x.lim),y <- c(cv$alpha,cv$alpha),lty=3)
      text(cv$power.curve.x.lim*0.95,cv$alpha+0.05,bquote(alpha),pos=4,cex=1.5)
      text(cv$power.curve.x.lim*0.01,0.9,bquote(d == .(cv$power.d)),pos=4,cex=1.5)# == frac(paste("|",.(cv$mx1)-.(v$mx0),"|",sep=""),.(v$sx)) == .(cv$power.d)
      text(cv$power.curve.x.lim*0.01,0.7,bquote(1 - beta == .(round(cv$power,2))),pos=4,cex=1.5)
    }
  }, height = 600)
})

