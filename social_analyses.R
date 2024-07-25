
## Import libraries ------------------------------------------------------------
library(tidyverse)  # Keep script tidy
library(glue)       # String formatting throughout
library(pbapply)    # Progress bars for *apply functions
library(readr)
library(dplyr)
library(magrittr)
library(ggplot2)
library(qwraps2)
library(reshape2)
library(data.table)
library(car)
library(psych)
library(BayesFactor)


## Clear workspace -------------------------------------------------------------
rm(list = ls())

## Utility functions -----------------------------------------------------------
# If on windows, transform path to appropriate format
check.path <- function(path) {
  if (.Platform$OS.type == "windows" ) {
    path %>% str_replace('/media/labs', 'L:') %>%
      str_split('/') %>%
      `[[`(1) %>%
      paste(collapse = '\\')
  } else {
    path
  }
}

# Import instead of sourcing files -- returns an environment the file is loaded
# into, to keep contents of the file separate from global workspace
import <- function(path, ...) {
  n.env <- new.env(); source(check.path(path), local = n.env, ...); n.env
}

setwd("L:/rsmith/wellbeing/tasks/SocialMedia/")
select=dplyr::select
rename=dplyr::rename
`%!in%` = Negate(`%in%`)
## Social Media Task Analyses ----
source("L:/rsmith/lab-members/clavalley/R/functions/combine_social_fits.R")
result_dir='./output/'
combine_social_fits(root='./output/50tr/', 
                    result_dir = glue('{result_dir}'))
social.df <- read.csv(glue("{result_dir}/fits_{Sys.Date()}.csv"))
social.df <- social.df %>% filter(!is.na(room_type)&!is.na(session))

## Bar plots ----
local.barplot <- function(df, x.var, y.var, ses, color.var=NULL){
  if(is.null(color.var)){color.var = x.var}else{color.var=color.var}
  df %>%
    filter(session %in% ses) %>%
    ggplot(., aes(x=!!sym(x.var), y=!!sym(y.var), fill=!!sym(color.var), group = !!sym(color.var))) +
    geom_bar(fun = mean, stat = 'summary', alpha = 1, position = position_dodge()) +
    stat_summary(func.y = mean_se, geom = "errorbar", color =  "black", 
                 width = .25, position = position_dodge(.9))
  
}
head(social.df)

social.df$session <- as.factor(social.df$session)
social.df$counterbalance <- as.factor(social.df$counterbalance)


social.df %>% 
    local.barplot(., x.var='session', y.var='p_high_information_h5_h1_diff', ses=c(1), color.var = 'room_type')
social.df %>% 
  local.barplot(., x.var='session', y.var='p_high_information_h5_h1_diff', ses=c(2), color.var = 'room_type')



social.df %>% 
  local.barplot(., x.var='session', y.var='fit_info_bonus_alpha__h5_h1_diff', ses=c(1), color.var = 'room_type')

social.df %>% 
  local.barplot(., x.var='session', y.var='fit_info_bonus_alpha__h5_h1_diff', ses=c(2), color.var = 'room_type')


source("L:/rsmith/smt-lib/f.R")
source('L:/rsmith/smt-lib/corrplotplus.R')

social.df %>% filter(session ==1) %>%
  select(c(4:ncol(social.df))) %>% 
corrplotplus(., rows = c(1:4, 11:12, 16, 21), cols = c(5:10, 13:15), R.cex = .4, sig.cex = .5 ,BF.cex =.3, lab.size = .5)

# Figure 1c
social.media.roomtype = list(
  `Like`   = "Like", 
  `Dislike` = "Dislike", 
  `All`    = c("Like", "Dislike")
)
horizon.frac_correct = function(db, room="All") {
  df = db %>% filter(room_type %in% social.media.roomtype[[room]])
  
  measures = c(
    "h5_freec1_acc",
    "h5_freec2_acc",
    "h5_freec3_acc",
    "h5_freec4_acc",
    "h5_freec5_acc",
    "h1_freec1_acc"
  )
  
  df <- reshape2::melt(df,
                       id.vars = c("subject"),
                       measure.vars = measures,
                       variable.name = "free_choice",
                       value.name = "frac_correct"
  )
  
  df$horizon <- as.factor(substr(df$free_choice, start=1, stop=2))
  df$free_choice <- as.integer(substr(df$free_choice, start=9, stop=9))
  
  ggplot(df, aes(x=free_choice, y=frac_correct, color=horizon, group=horizon)) +
    stat_summary(geom="line", fun=mean) + stat_summary(geom="point", fun=mean) +
    stat_summary(geom="errorbar", fun.data=mean_se, width = 0.2) +
    scale_y_continuous(
      limits=c(0.0, 1)
    ) +
    scale_x_continuous(
      breaks=seq(1, 6)
    ) +
    coord_cartesian(
      ylim=c(0.5, 1)
    ) +
    labs(
      x="Free Choice Trial Number",
      y="Fraction Correct",
      title="Fraction Correct vs Free-Choice Trial Number",
      subtitle=paste(room,"Session _")
    ) +
    theme(text = element_text(size=16), axis.title = element_text(size=20))
}
social.df %>% filter(session==2) %>%
horizon.frac_correct(db=., room='Like')

# Figure 2a ----

social.media.info.cond = list(
  unequal="13"
)
horizon.choice_curve = function(db, info_cond='unequal', room="All", line.type=2) {
  df = db %>% filter(room_type %in% social.media.roomtype[[room]])
  
  check_for = "more_info"
  check_for_label = "Unequal"
  
  diffs = c("24", "12", "08", "04", "02");
  mod   = c("less", "more")
  hor   = c("h1", "h5")
  
    y_axis = "Probability of Choosing More Informative Option"
    x_axis = "Difference in Generative Means between More and Less Informative Options"
  
  measures = apply(expand.grid(hor, check_for, diffs, mod), 1, function(x) paste0(x, collapse="_"))
  
  df <- reshape2::melt(df,
                       id.vars = c("subject"),
                       measure.vars = measures,
                       variable.name = "mean_diff",
                       value.name = "prob"
  )
  
  check_sign = function(str) {if(str == "more") {1} else {-1}}
  
  df$Horizon <- as.factor(str_sub(df$mean_diff, 1, 2) %>% toupper)
  df$mean_diff = as.integer(str_sub(df$mean_diff, -7, -6)) * mapply(check_sign, str_sub(df$mean_diff, -4, -1))
  
  # fit <- nls(prob ~ SSlogis(mean_diff, Asym, xmid, scal), data = df)
  # print(fit %>% summary)
  
  ggplot(df, aes_string(x="mean_diff", y="prob", color="Horizon", group="Horizon")) +
    {if(line.type==1)stat_summary(geom="line", fun=mean, linewidth = 1.2)} +
    stat_summary(geom="point", fun=mean) +
    stat_summary(geom="errorbar", fun.data=mean_se) +
    {if(line.type==2)geom_smooth(method="nls", 
                formula=y ~ SSlogis(x, Asym, xmid, scal), se = FALSE)} +
    scale_y_continuous(
      limits=c(0.0, 1),
      breaks=seq(0.0, 1.0, 0.2)
    ) +
    scale_x_continuous(
       breaks=c(-24, -12, -8, -4, -2, 2, 4, 8, 12, 24)
     # breaks = seq(-24, 24, 4)
    ) +
    labs(
      x=x_axis,
      y=y_axis,
      title=glue("Difference in Generative Means vs Choice Probability ({check_for_label} Information Condition)"),
      subtitle=paste(room,"Session 2") #SPECIFY SESSION NUMBER
    ) +
    theme(text = element_text(size=10), 
          axis.title = element_text(size=12), 
          panel.grid.major.x = element_blank(), 
          panel.grid.minor.x = element_blank()
    )
}

social.df %>% filter(session==2) %>% #look at one session at a time
  horizon.choice_curve(., room='Dislike', line.type=2) #line.type=1 means edges, line.tye=2 means logistic curve

## SELF-REPORT ----
subs <- social.df %>% pull(subject) %>% unique
source("L:/rsmith/lab-members/clavalley/R/functions/pull_feedback_files.R")
feedback.df <- pull_feedback_files("L:/NPC/DataSink/StimTool_Online/WBMTURK_Social_MediaCB2/", subject_list = subs)


source("L:/rsmith/lab-members/clavalley/R/functions/grab_files.R")
datasink='L:/NPC/DataSink/StimTool_Online/WBMTURK_Social_MediaCB2/'

#### post-task ----
post.task.df <- grab.files(root=datasink, file.var = 'post_task') %>%
  dplyr::relocate(subject, .before = 'question') %>%
  filter(subject %in% subs)

failed.attention.ids <- post.task.df %>% filter(passed.attention == F) %>% pull(subject)
#### panasx ----

panasx.files <- grab.files(root=datasink, file.var = 'panasx') %>% as.data.frame  %>% 
  relocate(subject, .before = 'question') %>%
  mutate(question = sub(".*panasx_ ", "", question))
panasx.files$rating <- panasx.files$rating %>% as.numeric

#write.csv(panasx.files, 'L:/rsmith/lab-members/clavalley/studies/development/wellbeing/social_media/self_report/panasx_responses.csv', row.names = F)

panasx.files <- panasx.files %>% pivot_wider(id_cols = 'subject', names_from = 'question', values_from = 'rating')

#### well-being ----

wellbeing.files <- grab.files(root=datasink, file.var = 'well_being') %>% as.data.frame %>%
  relocate(subject, .before = 'question') %>% mutate(rating = sub(".*Item ", "", rating)) %>%
  filter(!grepl("TRQ", question))
wellbeing.files$rating <- wellbeing.files$rating %>% as.numeric
wellbeing.files$question = paste('wb', wellbeing.files$question, sep='_')

#write.csv(wellbeing.files, 'L:/rsmith/lab-members/clavalley/studies/development/wellbeing/social_media/self_report/well_being_responses.csv', row.names = F)

wellbeing.files <- wellbeing.files %>% filter(passed.attention.1 == T & passed.attention.2 ==T)


#### demographics ----

demo.files <- grab.files(root=datasink, file.var = 'demo') %>% as.data.frame  %>% 
  relocate(subject, .before = 'question') %>%
  filter(!grepl("TRQ", question)) %>%
  mutate(question = case_when(question=='question1_sex' ~ 'Sex',
                              question=='question2_gender' ~ 'Gender',
                              question=='question15_sexual-orientation' ~ 'Sexual_Orientation',
                              question=='question3_age' ~ 'Age',
                              question=='question4_country' ~ 'Country_LiveIn',
                              question=='question6_race' ~ 'Race',
                              question=='question5_eth' ~ 'Hisp/Latin',
                              question=='question7_english' ~ 'English_primary',
                              question=='primaryLang' ~'Other_Primary_Lang',
                              question=='question9_relationship' ~ 'Relationship_Status',
                              question=='question10_children' ~ 'Num_Bio_Kids',
                              question=='question11_step-adopted' ~ 'Num_Step_Kids',
                              question=='question12_home' ~ 'Home_Living',
                              question=='question13_education' ~ 'Education',
                              question=='question16_employed' ~ 'Employment_Type',
                              question=='question14_employment' ~ 'Occupation_Type',
                              question=='question18_conditions' ~ 'Disability_Status')) 


demographics <- demo.files %>% pivot_wider(id_cols = 'subject', names_from = 'question', values_from = 'rating') %>%
  mutate(Sex = case_when(Sex=='item1' ~ 'Female',
                         Sex=='item2' ~ 'Male',
                         Sex=='item3' ~ 'Intersex/Other')) %>%
  mutate(Gender = case_when(Gender=='item1' ~ 'Cis Woman',
                            Gender=='item2' ~ 'Cis Man',
                            Gender=='item3' ~ 'Trans Woman',
                            Gender=='item4' ~ 'Trans Man',
                            Gender=='item5' ~ 'Non-binary',
                            Gender=='item6' ~ 'Genderqueer/Gender nonconforming',
                            Gender=='item7' ~ 'Prefer not to say')) %>%
  mutate(Sexual_Orientation = case_when(Sexual_Orientation=='item1' ~'Asexual',
                                        Sexual_Orientation=='item2' ~'Bisexual',
                                        Sexual_Orientation=='item3' ~'Demisexual',
                                        Sexual_Orientation=='item4' ~'Gay/Lesbian',
                                        Sexual_Orientation=='item5' ~'Hetero/Straight',
                                        Sexual_Orientation=='item6' ~'Pansexual',
                                        Sexual_Orientation=='item7' ~'Prefer not to say')) %>%
  mutate(Country_LiveIn = ifelse(Country_LiveIn=='item187','USA', Country_LiveIn)) %>%
  mutate(Race = case_when(Race=='item1' ~ 'Asian',
                          Race=='item2' ~ 'Black/AA',
                          Race=='item3' ~ 'AI/AN',
                          Race=='item4' ~ 'Hawaiian/PI',
                          Race=='item5' ~ 'White',
                          Race=='item6' ~ 'Prefer not to say',
                          Race=='item7' ~ 'IDK')) %>%
  mutate(`Hisp/Latin` = case_when(`Hisp/Latin`=='item1' ~ 'Yes',
                                  `Hisp/Latin`=='item2' ~ 'No',
                                  `Hisp/Latin`=='item3' ~ 'Prefer not to say',
                                  `Hisp/Latin`=='item4' ~ 'IDK')) %>%
  mutate(English_primary = case_when(English_primary == 'item1'~ T,
                                     English_primary == 'item2'~ F)) 



#### combined ----

temp <- wellbeing.files %>% select(-c(passed.attention.1, passed.attention.2)) %>%
  pivot_wider(id_cols = 'subject',names_from = 'question', values_from = 'rating') %>% 
merge(social.df, ., by='subject')

full.socialmedia.selfreport.df <- merge(temp, panasx.files, by='subject')


## CORRELATIONS ----

full.socialmedia.selfreport.df %>% 
  select(4:ncol(full.socialmedia.selfreport.df)) %>% 
  relocate(starts_with('fit'), .before = p_high_information_h1) %>%
  corrplotplus(., rows = 1:8, cols=9:25, R.cex = .7, sig.cex = .5 ,BF.cex =.6, lab.size = .7)

source("L:/rsmith/lab-members/clavalley/R/functions/scatterplot_func.R")

scatterplot.func(full.socialmedia.selfreport.df[4:ncol(full.socialmedia.selfreport.df)], 
                 x.var = 'fit_info_bonus_alpha_h1', y.var = 'p_high_information_h5_h1_diff',
                 x.lab = 'info bonus h1', y.lab = 'phigh diff')







## Test Retest ----
library(irr)
temp <- social.df %>%
  pivot_wider(id_cols = c('subject','room_type', 'counterbalance'), names_from = 'session', 
              values_from = c('fit_info_bonus_alpha_h5',
                              'fit_info_bonus_alpha_h1',
                              'fit_info_bonus_alpha__h5_h1_diff',
                              'fit_decision_noise_sigma_13_h1',
                              'fit_decision_noise_sigma_13_h5',
                              'fit_decision_noise_13_h5_h1_diff', 
                              'p_high_information_h5_h1_diff')) %>% as.data.frame 

temp %>% 
  filter(room_type=='Like') %>%
  filter(counterbalance==1) %$%
  icc(.[c('fit_info_bonus_alpha_h5_1','fit_info_bonus_alpha_h5_2')], model = 'twoway', type='consistency')



