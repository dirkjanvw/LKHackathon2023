###Draft Hackathon

###Draft Hackathon

#### Part 1: Working with phenotypes
###########LIBRARIES
library(openxlsx)
library(ggplot2)
##########

###LIST OF FILES NEEDED FOR THIS PART
#Hackathon_Phenotypes_Rep1.xlsx
#Hackathon_Phenotypes_Rep2.xlsx
#Species_info.xlsx
############


####Loading in your raw phenotype data from excel files
raw.phenotypes.rep1 <- read.xlsx("./Hackathon_Phenotypes_Rep1.xlsx")
raw.phenotypes.rep2 <- read.xlsx("./Hackathon_Phenotypes_Rep2.xlsx")

##Combining replicates
raw.phenotypes <- rbind(raw.phenotypes.rep1,raw.phenotypes.rep2) #rbind is a function that combines two tables by row
#DJ: Do these files have headers? If so, are the combined correctly?

#raw.phenotypes.X <- read.xlsx("PathToExcelSheet") ###Example if you want to load you own phenotypes


####Exploring the phenotypes

#Q1: What phenotypes did we load? How many samples do we have?
colnames(raw.phenotypes.rep1) #Different phenotype names
nrow(raw.phenotypes.rep1) #Number of LK accessions

#Q2: What are the distributions of our phenotypes (by horticultural type)?
lk.ID <- read.xlsx("./Species_info.xlsx") ###We load in information about the LK accessions
lk.subtype <- lk.ID$Subgroup_SB[match(raw.phenotypes.rep1$accession,lk.ID$LKID)] ###We extract the subtype information by LK ID
table(lk.subtype) #We look at what subtypes are represented in our set

## lets check the phenotypic distribution.
phenotype <-raw.phenotypes$green.trimmed_mean_10.250621 
horti_types <- lk.ID$Subgroup_SB[match(raw.phenotypes$accession,lk.ID$LKID)] 
to.plot <- data.frame(horti_types,phenotype)
ggplot(to.plot,aes(phenotype))+
  geom_histogram(aes(fill=horti_types),bins = 100)+
  theme_light()

ggplot(to.plot,aes(phenotype))+
  geom_histogram(aes(fill=horti_types),bins = 100)+
  facet_grid(horti_types~.)+
  theme_light()


## lets check the phenotypic distribution over the horticultural types.
phenotype <-raw.phenotypes$green.trimmed_mean_10.250621 
horti_types <- lk.ID$Subgroup_SB[match(raw.phenotypes$accession,lk.ID$LKID)] 
to.plot <- data.frame(horti_types,phenotype)
ggplot(to.plot,aes(horti_types,phenotype))+
  geom_boxplot(aes(fill=horti_types))+
  theme_light()


## lets check the phenotypic distribution over the genotypes.
phenotype <-raw.phenotypes$green.trimmed_mean_10.250621 
genotypes <- lk.ID$LKID[match(raw.phenotypes$accession,lk.ID$LKID)] 
to.plot <- data.frame(genotypes,horti_types,phenotype)
mp.per.g <- aggregate(to.plot$phenotype,list(to.plot$genotypes),mean,na.rm=T)
to.plot$genotypes <- factor(to.plot$genotypes,levels = mp.per.g$Group.1[order(mp.per.g$x)])
ggplot(to.plot,aes(genotypes,phenotype))+
  geom_boxplot(aes(fill=horti_types))+
  facet_grid(.~horti_types,scale="free_x",space="free_x")+
  theme_light()



#####Calculating broad sense heritability (BSH)
## To get an estimate of how much environment and genetics contribute to trait variation we can estimate the
## broad sense heritability of our trait of interest. If we know the approximate BSH, we can interpret GWAS results better.
## To calculate BSH, we need the raw phenotype values, including all replicates.

pheno.res <- lm(raw.phenotypes$green.trimmed_mean_10.250621~raw.phenotypes$accession)
pheno.res.anova <- anova(pheno.res)

BSH <- (pheno.res.anova$`Mean Sq`[1]-pheno.res.anova$`Mean Sq`[2])/(pheno.res.anova$`Mean Sq`[1]+pheno.res.anova$`Mean Sq`[2])
#DJ: Is there no easier way to do this? I'm thinking about maybe a library that does this for you?
#DJ: Some possible libraries suggested by AI (not checked myself) are: heritability and agricolae
BSH


## Our phenotypes are not ready for GWAS yet. We need to normalize the trait (if needed) and prepare it
## to be used as an input for our GWAS script. For now we will create a phenotype matrix where rows are the phenotypes
## and columns are the LK accessions


#Q3: What type of measurement do we have? It can be counts, ratios, binary/ordinal values or 
## quantitative measurements.We have replicates so we also have to first take the average across the replicates

phenotypes.diff.mean <- (raw.phenotypes.rep1[,-1]+raw.phenotypes.rep2[,-1])/2
rownames(phenotypes.diff.mean) <- raw.phenotypes.rep1$accession
phenotypes.diff.mean <- t(phenotypes.diff.mean) #We move the table around so each row is a phenotype
#DJ: There are easier ways to normalise data. I would suggest using the scale function from the base R library.

#Q4: Save phenotype file as input file for GWAS script.

save(phenotypes.diff.mean,file="./phenotypes_for_GWAS.out")

############NEW SCRIPT ####################Running GWAS on our phenotypes
##Libraries
## load needed packages
library(Matrix)
library(MASS)
library(ggplot2)
library(qqman)
library(ggplot2)
library(cowplot)
# for Step 1: linear mixed model (no SNPs)
library(lme4qtl) 
#install.packages("devtools")
#devtools::install_github("variani/lme4qtl")
# for Step 2: association tests
#install.packages("devtools")

library(matlm)
#install.packages("devtools")
#devtools::install_github("lmehrem/matlm")
library(wlm)
#devtools::install_github("variani/wlm")

library(tictoc)
library(dplyr)

##############################

###LIST OF FILES NEEDED FOR THIS PART

#############################

## During GWAS we use linear models to test the association of a genetic variant (SNP,PAV,CNV,kmer) 
## with the trait of interest. For this workshop we run GWAS with SNPs.


##One important step is calculating a kinship matrix. The kinship matrix is used during the GWAS to correct
##for false positive associations by taking into account population structure. We can get an estimate of kinship
##calculating the covariance of the SNPs.


load("/Users/6186130/Documents/LettuceKnow/Hackathon_2023/Data/BGI_Sat_kinship.out")
#DJ: Maybe use a relevant path here as well?
heatmap(letkin)
#DJ: This variable does not exist yet?

## We prepared our phenotype input and saved it as phenotypes_for_GWAS.out

## Below you will find the GWAS script we will use. First you run the function as a whole (Line X to Y). Then you can proceed.
#DJ: If they simply do Ctrl+Enter on the start of the function definition, they will run the whole function.
#DJ: (Instead of mentioning line numbers.)

GWAS <- function(genotypes, trait, phenotype.name, kinship, out.dir,
                 give.pval.output.in.R = F, maf.thr = 0.95, snp.info) {
  
  ## Prep trait/phenotypes
  phenotype <- toString(phenotype.name)
  #DJ: Haha didn't know this was possible in R too, I only know it from Java. I would have expected `as.character` here.
  letkin <- kinship
  usemat <- genotypes
  selc <- !is.na(trait) #Selects the lines with an observation (removes lines that have an NA)
  trait.names <- trait[selc]
  use.trait <- trait[selc]
  print("Traits are selected.")
  print(paste("The phenotype ID is ", phenotype,".", sep=""))
  print(max(usemat,na.rm = T))
  
  ## Filter in usemat and kinship object for mapping
  usemat <- usemat[,selc]
  letkin <- letkin[selc,selc]
  print(dim(letkin))

  ## Filter again MAF 5%
  #DJ: this 5% is not hardcoded but taken from the maf.thr parameter! Also, I thought MAF should be the lowest of (1-MAF) and MAF? So 0.95 should be 0.05?
  threshold <- round(ncol(usemat)*maf.thr, digits=0)
  print(threshold)
  maf.filter.quick <- apply(usemat == 1,1,sum)> threshold  | apply(usemat == 3,1,sum) > threshold ### <-- this is quicker!
  print(paste0("SNPs falling within MAF >= ",(1-maf.thr)*100,"%" ))
  print(table(maf.filter.quick))
  usemat <- usemat[!maf.filter.quick,]
  snp.info <- snp.info[!maf.filter.quick,]
  print("Genotype matrix filtered and transformed.")
  
  ## Prune SNP set
  phe.snp.cor <- cor(use.trait,t(usemat),use = "pairwise") ###Calculate correlation of SNPs
  print("SNP correlation calculated.")
  phe.snp.cor[is.na(phe.snp.cor)] <- 0 ##Set NAs to 0
  
  snp.selc <- abs(phe.snp.cor)>0.3 & !is.na(phe.snp.cor) 
  #DJ: Maybe put this 0.3 in as a parameter as well?
  usemat.pruned <- usemat[snp.selc,] ##Remove SNPs with an absolute correlation lower than 0.3
  print("SNPs pruned")
 
  ### start mapping by making decomposition
  ID <- rownames(letkin) ; length(ID)
  cbind(ID,use.trait)
  mod <- lme4qtl::relmatLmer(use.trait ~ (1|ID), relmat = list(ID = letkin))

  ##Calculate heritability
  #DJ: Again?
  herit.mod <- lme4qtl::VarProp(mod)
  V <- lme4qtl::varcov(mod, idvar = "ID")
  V_thr <- V
  V_thr[abs(V) < 1e-10] <- 0
  decomp <- wlm::decompose_varcov(V, method = "evd", output = "all")
  W <- decomp$transform
  print("Decomposition of covariance matrix was performed.")
  
  ## make data object for mapping without any extra factors
  nnn <- rep(1,ncol(letkin))
  # class(use.trait)
  # class(nnn)
  # class(usemat)

  ### GWAS with kinship
  gassoc_gls <- matlm(as.numeric(use.trait) ~ nnn, nnn, pred =  t(usemat.pruned), ids = rownames(W), transform = W, batch_size = 4000, verbose = 2, cores = 1,stats_full = T)
  #DJ: Since cores are mentioned, is it possible to multithread this?

  ###Add SNPs we didnt test back
  
  lod <- rep(0.9,nrow(snp.info))
  lod[snp.selc] <- gassoc_gls$tab$pval##Here we add the SNPs we tested, teh rest is 0
  
  zscore <- rep(0,nrow(snp.info))
  print(table(is.na(zscore)))
  zscore[snp.selc] <- gassoc_gls$tab$zscore ##Here we add the SNPs we tested, the rest is 0
  print(table(is.na(zscore)))
  mrkno <- which.max(lod)
  
  se <- rep(0,nrow(snp.info))
  se[snp.selc] <- gassoc_gls$tab$se ##Here we add the SNPs we tested, the rest is 0
  
  b <- rep(0,nrow(snp.info))
  b[snp.selc] <- gassoc_gls$tab$b ##Here we add the SNPs we tested, the rest is 0

  
  
  ###Save as integers
  gassoc_gls <- snp.info
  gassoc_gls$pval <- lod
  gassoc_gls$zscore <- as.integer(zscore*10000)
  print(table(is.na(gassoc_gls$zscore)))
  gassoc_gls$se <- as.integer(se*10000)
  gassoc_gls$b <- as.integer(b *10000)
  gassoc_gls$SNP <- paste(gassoc_gls$CHR,gassoc_gls$POS,sep="_")
  save(gassoc_gls,file=paste(out.dir,"/GWAS_result_",phenotype,".out",sep=""))
  save(herit.mod,file=paste(out.dir,"/Heritability_estimate_",phenotype,".out",sep=""))
  cofac <- usemat[mrkno,]
  save(cofac,file=paste(out.dir,"/GWAS_cofac.out",sep=""))
  print("Results saved.")
  if( give.pval.output.in.R ){
    return(gassoc_gls)
  }
}

########################START SCRIPT#########################
ext.dir <- "./"
#DJ: This is not needed since it is the current directory?
main.dir <- paste(ext.dir,"/GWAS_Results/",sep="")
dir.create(main.dir)

###INPUT

#### Load phenotype data
pheno <- load("/Users/6186130/Documents/LettuceKnow/Hackathon_2023/Data/phenotypes_for_GWAS.out")
#DJ: Don't hardcode paths
pheno <- eval(parse(text=pheno))
rm(phenotypes.diff.mean)
base.dir <- paste(main.dir, "BGI_",sep="") ##Indicate which variants were used

#Load genotype object for GWAS mapping
usemat <- load("/Users/6186130/Documents/LettuceKnow/Hackathon_2023/Data/sat.snps.out")
#DJ: Don't hardcode paths
usemat <- eval(parse(text=usemat))
snp.info <- usemat[,1:3]
usemat <- data.matrix(usemat[,-c(1:3)])
rm(sat.snps)


#Load kinship matrix
load("/Users/6186130/Documents/LettuceKnow/Hackathon_2023/Data/BGI_Sat_kinship.out")
#DJ: Don't hardcode paths

###Input phenotype
trait <- rownames(pheno)[4] ###TODO:Here I could make it in a for loop...or let them choose by hand
new.dir <- paste(base.dir,trait,sep="")
dir.create(new.dir)
print(colnames(pheno))
pheno <- pheno[,colnames(pheno) %in% colnames(letkin)]
#DJ: Just out of curiosity, why use %in% here and match() up above?
print(ncol(pheno))

## Prep sets for GWAS
log.file.w <- file(paste(new.dir,"/","BGI_",trait,"_warning.log",sep=""),open="wt")
sink(file=log.file.w,type="message")

letkin <- letkin[names(pheno[4,]),names(pheno[4,])] #In case we do not have information for all lines with this phenotype
usemat<- usemat[,names(pheno[4,])] #In case we do not have information for all lines with this phenotype

#GWAS(genotypes = usemat_in, trait = as.vector(pheno[trait,]), phenotype.name = trait, kinship=letkin_in, out.dir=new.dir,
     #maf.thr = 0.95,give.pval.output.in.R = F)
# or 
GWAS.output <- GWAS(genotypes = usemat, trait = as.vector(pheno[trait,]), phenotype.name = trait, kinship=letkin, out.dir=new.dir,
                    maf.thr = 0.95,give.pval.output.in.R = T,snp.info=snp.info)

sink(type="message")
close(log.file.w)

print(paste("GWAS finished. Phenotype is ",trait,sep=""))
#print(paste(nrow(pheno) - i," traits of ",nrow(pheno)," to go.",sep=""))
lifecycle::last_lifecycle_warnings()


#Q3: Plot the manhattan plots for the GWAS run 

##
##INSERT MANHATTAN PLOT CODE


load("/Users/6186130/Documents/LettuceKnow/LKHackathon2023/GWAS_Results/BGI_green.trimmed_mean_10.250621/GWAS_result_green.trimmed_mean_10.250621.out")
#DJ: Don't hardcode paths
bf <- -log10(0.05/nrow(gassoc_gls)) #Bonferroni threshold
gassoc_gls$POS <- gassoc_gls$POS/1000000
#DJ: Why 1000000? Maybe explain this.
gassoc_gls.topl <- gassoc_gls[-log10(gassoc_gls$pval) >1,]

manhattan(gassoc_gls.topl,snp="SNP",chr="CHR",bp = "POS",p = "pval",logp = T,suggestiveline = F,
          genomewideline = bf,annotatePval = bf,col = c("royalblue4","skyblue"))

##############NEW SCRIPT############### GWAS Follow up

##Now that we have a locus (or more) that is associated with our phenotype of interest, we can go further
##by investigating what genes we find within these loci.

##Load gene annotation file
gene.anno <- read.delim("/Users/6186130/Documents/LettuceKnow/Hackathon_2023/Data/20221208_Lactuca_sativa.annotation_overview.tsv")
#DJ: Don't hardcode paths

gassoc_gls_sig <- gassoc_gls[-log10(gassoc_gls$pval) > bf,] ##Only choosing significant SNPs
peak <- do.call(data.frame,aggregate(POS ~ CHR, gassoc_gls_sig, function(x){ c(min(x),max(x))})) #We extract the peaks per chromosome

genes.per.peak <- apply(peak,1,function (x) {
  chromosome <- as.character(x[1])
  start.pos <- x[2]-0.05
  end.pos <- x[3]+0.05
  locus.info <- gene.anno[gene.anno$chromosome.number == chromosome & 
              between(gene.anno$start.sequence/1e6,start.pos,end.pos),]})
genes.per.peak <- do.call(rbind,genes.per.peak)


###To zoom into the region and determine specific blocks, we choose the Top SNP of that region, and calculate its 
###Correlation to all other SNPs in that window. SNPs correlating with each other usually indicates a form of linkage.

locus <- 5 ##Choosing the peak on Chromosome 5
gassoc_gls_cor <- gassoc_gls_sig[gassoc_gls_sig$CHR ==as.character(locus),] ##Creating the object for the plot
top.snp <- gassoc_gls_cor[which.max(gassoc_gls_cor$pval),1:3]
top.snp.mat <- usemat[which(snp.info$CHR == as.character(top.snp$CHR)&snp.info$POS/1e6 == top.snp$POS),]

##Here we use a function to get all SNPs within the window of interest (with 50kb up and downstream included)
snp.mat.to.cor <- as.numeric(apply(peak[peak$CHR==locus,],1,function (x) { 
  chromosome <- as.character(x[1])                                       
  start.pos <- x[2]-0.05
  end.pos <- x[3]+0.05
  snp.to.cor <- which(snp.info$CHR == chromosome &
                           between(snp.info$POS/1e6,start.pos,end.pos))
  return(snp.to.cor)
}
  ))

usemat.cor <- usemat[snp.mat.to.cor,] ##Selecting the SNPs from the genotype matrix
snp.info.cor <- snp.info[snp.mat.to.cor,] ###And their positional info

top.snp.cor <- cor(top.snp.mat,t(usemat.cor)) #Correlating the Top SNP to all others
snp.cor.to.pl <- cbind(as.numeric(top.snp.cor),snp.info.cor)
snp.cor.to.pl$POS <- snp.cor.to.pl$POS/1e6
snp.cor.to.pl <- merge(snp.cor.to.pl, gassoc_gls, by=c("CHR","POS"), all.x=TRUE)
colnames(snp.cor.to.pl)[3]<- "correlation.topsnp"

mhpl <- ggplot(snp.cor.to.pl[between(snp.cor.to.pl$POS,92.5,93.2),],aes(POS,-log10(pval)))+
  geom_point(aes(colour = correlation.topsnp),alpha=1)+
  scale_colour_gradient2(low = "chocolate", high="darkgreen",mid="skyblue1")+
  xlab("Position (Mbp)") + ylab("-log10(p)") +
  theme_cowplot()+
  geom_hline(yintercept=7.52, linetype='dotted', col = 'red',size=1)+
  
  theme(panel.border = element_rect(colour = "black",linetype = "solid"), 
              axis.title.x=element_blank(),
              axis.text.x=element_blank(),
              axis.ticks.x=element_blank(),
            text=element_text(size=15))
  
mhpl

anno.plot <- ggplot(test[which(test$chromosome.number == as.character(locus))&between(test$start.sequence/1e6,92.5,93.2),])+
 geom_segment(aes(x=start.sequence/1e6, xend=stop.sequence/1e6, y=chromosome.number, yend=chromosome.number,color=type), 
              size=5,alpha=0.8)+
 xlab("Position (in Mb)") +
 ylab("Annotation")+
  theme(text=element_text(size=15))
  

full.locus.plot <- plot_grid(mhpl,anno.plot,ncol = 1,align = "v",rel_heights = c(2,0.5))
full.locus.plot
