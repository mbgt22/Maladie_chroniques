library(shiny)
library(colourpicker)
library(data.table)
require(rgdal)
require(sp)
library(ggplot2)
library(rnaturalearth)
library(gridExtra)

library(highcharter)
library(dplyr)

############ Chargez la base de données au démarrage de l'application
inegalite <- fread("er_inegalites_maladies_chroniques.csv", stringsAsFactors = TRUE)
inegalite <- na.omit(inegalite)
prevalence <- inegalite[type == "prevalence"]
incidence <- inegalite[type == "incidence"]
unique(incidence$valgroupage)

############renommage des variables de vargroupage
etude<-c("sans diplôme","BEP/CAP","niveau bac","études supérieures")
profession<-c("Enseignement supérieur", 
              "Agriculteurs exploitants",
              "Artisans, commerçants, chefs d'entreprise",
              "Cadres et professions intellectuelles supérieures",
              "Professions intermédiaires",
              "Employés",
              "Ouvriers",
              "Retraités",
              "Autres")
richesse<-c("Dixième le plus modeste de la population",
            "Deuxième dixième le plus modeste de la population",
            "Troisième dixième le plus modeste de la population",
            "Quatrième dixième le plus modeste de la population",
            "Cinquième dixième le plus modeste de la population",
            "Cinquième dixième le plus aisé de la population",
            "Quatrième dixième le plus aisé de la population",
            "Troisième dixième le plus aisé de la population",
            "Deuxième dixième le plus aisé de la population",
            "Dixième le plus aisé de la population")



############## Définir le risque relatif par région et par maladie
extraction <- function(region=c(1, 2, 3, 4, 5, 6, 7, 8, 11, 24, 27, 28, 32, 44, 52, 53, 75, 76, 84, 93, 94), maladie) {
  nouv_data <- incidence[varpartition == "FISC_REG_S" & 
                           vargroupage == "FISC_NIVVIEM_E2015_S_moy_10" &  
                           catlib == maladie & valgroupage %in% c(1:10) & valpartition %in% region, 
                         .(vargroupage, valgroupage, varpartition, valpartition, txstanddir, catlib)]
  nouv_data$txstanddir[is.na(nouv_data$txstanddir)] <- median(nouv_data$txstanddir, na.rm = TRUE)
  nouv_data[, c("valgroupage", "valpartition") := .(as.numeric(as.character(valgroupage)), as.numeric(as.character(valpartition)))]
  moyennes <- nouv_data[, .(moyenne_txstanddir = mean(txstanddir, na.rm = TRUE)), by = valgroupage]
  
  moyenne_reference <- moyennes[valgroupage == 10, moyenne_txstanddir]
  
  moyennes<-moyennes[, ratio := ifelse(!is.na(moyenne_txstanddir) & !is.na(moyenne_reference) & moyenne_reference != 0, 
                                       moyenne_txstanddir / moyenne_reference, 
                                       NA)]
  
  result <- ggplot(data = moyennes, aes(x = valgroupage, y = ratio)) +
    geom_line(color = "blue") +
    geom_point() +
    labs(title = "le risque relatif par niveau de vie de a population ",
         x = "Niveau de vie de la population",
         y = "Risque relatif") +
    scale_x_continuous(breaks = seq(1, 10, 1))
  
  return(result)
}



#################
##créer un graphique risque relatif en fonction des variables 
############
choixvariable<-function(variable=c("EAR_GS_S","EAR_DIPLR_S","FISC_NIVVIEM_E2015_S_moy_10")){
  new_dt<-copy(incidence)
  
  if ("EAR_GS_S"%in%variable) {
    new_dt[vargroupage%in%variable, valgroupage := factor(valgroupage, levels = 1:9, labels = profession)]
  } else if ("EAR_DIPLR_S"%in%variable) {
    new_dt[vargroupage%in%variable, valgroupage := factor(valgroupage, levels = 1:4, labels = etude)]
  } else if ("FISC_NIVVIEM_E2015_S_moy_10"%in%variable) {
    new_dt[vargroupage%in%variable, valgroupage := factor(valgroupage, levels = 1:10, labels = richesse)]
  }
  new_dt <- new_dt[vargroupage %in% variable]

  maladie <- c(
    "Maladies inflammatoires ou rares ou VIH ou SIDA",
    "Diabète",                                       
    "Maladies cardioneurovasculaires",                
    "Traitements du risque vasculaire",              
    "Maladies neurologiques ou dégénératives",       
    "Traitements psychotropes",                       
    "Maladies psychiatriques",                        
    "Insuffisance rénale chronique terminale",        
    "Maladies respiratoires chroniques",             
    "Maladies du foie ou du pancréas",                
    "Cancers"
  )
  
  var_ref <- NULL
  var_groupage<-NULL
  result_variable <- list()
  list_of_plots <- list()
  
  
  
  for (i in 1:length(maladie)) {
    print(paste("Processing:", maladie[i]))
    var_data <- new_dt[catlib == maladie[i], .(vargroupage, valgroupage, txstanddir, catlib)]
    
    
    if ("EAR_GS_S" %in% variable){
      var_ref<-profession[4]
      var_groupage<-"Catégorie socio-professionnel"
    } else if ("EAR_DIPLR_S" %in% variable){
      var_ref<-etude[4]
      var_groupage<-"Niveau d'étude"
    } else if ("FISC_NIVVIEM_E2015_S_moy_10"%in% variable){
      var_ref<-richesse[10]
      var_groupage<-"Niveau de richesse"
    }
    print(paste("Valeur de var_ref:", var_ref))
    # Calcul de moyenne, moyenne_ref, et ratio
    var_data[, moyenne := mean(txstanddir, na.rm = TRUE), by = .(valgroupage, catlib)]
    moyenne_ref_value <- var_data[valgroupage ==var_ref & catlib == maladie[i], .(moyenne)][1, moyenne] 
    var_data[, moyenne_ref := moyenne_ref_value]
    var_data[, ratio := moyenne / moyenne_ref]
    var_data <- unique(var_data, by = c("vargroupage", "valgroupage", "catlib"))
    
    # Ajout du sous-ensemble à la liste 'resultat'
    result_variable[[i]] <- var_data 
    
    if(nrow(var_data) > 0) {
      graphe_var<- ggplot(var_data, aes(x = valgroupage, y = ratio)) +
        geom_bar(stat = "identity", fill = "steelblue") +
        geom_text(aes(label = round(ratio, 2)), vjust = -0.5, size = 3, color = "red") +
        labs(title = maladie[i], x = NULL, y = "risque relatif") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1),
              plot.title = element_text(size = 12))
      
      list_of_plots[[i]] <- graphe_var
      
    }
  }
  arranged_plots <- grid.arrange(grobs = list_of_plots, ncol = 3)
  return(arranged_plots)
}




##########inegalite d'esperance de vie 
esp_vie<-read.table("data esperance de vie.csv", header=TRUE, sep=";",dec=",",stringsAsFactors = TRUE)



esperance <- function(maladie_chronique){
  
  esp_vie_filtered <- esp_vie %>% filter(Categorie == maladie_chronique)
  
  plot <- ggplot(data = esp_vie_filtered, aes(x = Dixieme.de.niveau.de.vie, y = Esperance.de.vie),group=Sante,color=Sante) +
    geom_line(aes(color = Sante, group = Sante)) +
    geom_point(aes(color = Sante)) +
    labs(title = paste("Inégalités d'espérance de vie dues au", maladie_chronique),
         x = "Niveau de vie de la population",
         y = "espérance de vie ") +
    scale_x_continuous(breaks = 1:10, labels = richesse) +
    theme_minimal() +
    theme(legend.position = "right") + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(size = 12))
  
  return(plot)
}


#############présentation des libellés de vargroupage
libelle<-read.table("libelles_er1243.csv",header = TRUE,sep=";")
libelle<-libelle[,1:3]

#############affichage d'un extrait de la base de donnée
extraitbdd<-incidence[1:20,]
