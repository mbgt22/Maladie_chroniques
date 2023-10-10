library(shiny)
library(colourpicker)
library(data.table)
require(rgdal)
require(sp)
library(ggplot2)
library(rnaturalearth)
library(gridExtra)
require(leaflet)
library(dplyr)
library(sf)
library(highcharter)


############ Chargez la base de données au démarrage de l'application
sourceDonnees <- "Donnees/er_inegalites_maladies_chroniques.csv"
if (!file.exists(sourceDonnees)) {
  urlDonnees <- "https://data.drees.solidarites-sante.gouv.fr/explore/dataset/er_inegalites_maladies_chroniques/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B"
  download.file(url = urlDonnees, destfile = sourceDonnees)
}


inegalite <- fread(sourceDonnees, stringsAsFactors = TRUE, encoding = "UTF-8")
inegalite <- na.omit(inegalite)
prevalence <- inegalite[type == "prevalence"]
incidence <- inegalite[type == "incidence"]
unique(incidence$valgroupage)

lib <- as.data.table(readxl::read_excel("Donnees/libelles_er12432.xlsx"))

esp_vie<-fread("Donnees/data esperance de vie.csv", header=TRUE, sep=";",dec=",",stringsAsFactors = TRUE)

# Creation d'une table pour plot cartes des risques par maladies  ( t_geo)
cheminShp <- "Donnees/temp_geo.zip"
if (!file.exists(cheminShp)) {
  urlShp <- "https://gisco-services.ec.europa.eu/distribution/v2/nuts/download/ref-nuts-2021-10m.geojson.zip"
  download.file(url = urlShp, destfile = cheminShp)
}

unzip(zipfile = cheminShp, files = "NUTS_RG_10M_2021_3035_LEVL_1.geojson")
reg_geo <- read_sf("NUTS_RG_10M_2021_3035_LEVL_1.geojson") %>% subset(CNTR_CODE == "FR" & id != "FRY") %>% arrange(id)
file.remove("NUTS_RG_10M_2021_3035_LEVL_1.geojson")
reg_geo <- mutate(reg_geo, CODGEO = c(11, 24, 27, 28, 32, 44, 52, 53, 75, 76, 84, 93, 94))

t <- inegalite[  vargroupage == "FISC_NIVVIEM_E2015_S_moy_10" &
             varpartition == "FISC_REG_S" &
             type == "prevalence" &
             i_cat == 1][, .(g_dir = (txstanddir[valgroupage == 1] / txstanddir[valgroupage == 10]),
                             g_indir = (txstandindir[valgroupage == 1] / txstandindir[valgroupage == 10])), 
                         by = .(valpartition, catlib)][order(valpartition, -g_dir)]

t_geo <- merge(reg_geo, t, by.x = "CODGEO", by.y = "valpartition")


# Création de data.table pour la carte produite par highcharts
data_fr <- download_map_data("countries/fr/fr-all") %>% 
  get_data_from_map() 

data_fr <- as.data.table(data_fr)
data_fr$name[c(4,9,16)]<- c("Provence-Alpes-Côte d'Azur","Ile-de-France",
                            "Guyane")
data_fr <- data_fr[order(data_fr$name),]

lib_region <- lib[which(lib$var == "FISC_REG_S"),][-c(5,7,8),]
lib_region <- lib_region[order(lib_region$moda_lib),]

n.region <- data_fr[,lib_region$moda[which(lib_region$moda_lib == data_fr$name[-c(19)])]]
n.region <- append(n.region, NA)

data_fr<-data_fr[,numero_region := n.region] # on ajoute le numéro des régions aux données de la carte




############renommage des variables de vargroupage - Catég

diplome<-c("sans diplôme","BEP/CAP","niveau bac","études supérieures")

  
profession <- c("Enseignement supérieur", 
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

age <- c( "Moins de 30 ans"= "<30",
          "Entre 30 et 39 ans" = "30-39",
          "Entre 40 et 49 ans" = "40-49",
          "Entre 50 et 59 ans" = "50-59",
          "Entre 60 et 69 ans" = "60-69",
          "Entre 70 et 79 ans" = "70-79",
          "Entre 80 et 89 ans" = "80-89",
          "Plus de 90 ans " = ">=90")

sexe <-c("Femme" = "F", "Homme" = "H")


maladie <- c("Maladies cardioneurovasculaires" ="SUP_CV_CAT",
              "Maladies inflammatoires ou rares ou VIH ou SIDA" = "SUP_INFRARVIH_CAT",
              "Maladies neurologiques ou dégénératives" = "SUP_NEUDEG_CAT",
              "Traitements psychotropes" = "SUP_PSYMED_CAT",
              "Insuffisance rénale chronique terminale" = "SUP_RIRCT_CAT",
              "Cancers" =  "SUP_CAN_CAT",
              "Maladies respiratoires chroniques"= "TOP_ABPCOIR_IND",
              "Diabète" = "TOP_FDIABET_IND")
###### Définition des choix d'inputs et de leurs modalités#####


profession_lib <- as.vector(lib[var == "EAR_GS_S", moda_lib])
profession_moda <- as.vector(lib[var == "EAR_GS_S",moda])


diplome_lib <- as.vector(lib[var == "EAR_DIPLR_S", moda_lib])
diplome_moda <- as.vector(lib[var == "EAR_DIPLR_S", moda])

sexe_lib <- as.vector(lib[var == "SEXE", moda_lib]) 
sexe_moda <- as.vector(lib[var == "SEXE", moda]) 




# Fonction filtre

filter_var_Groupage <- function(donnees, inputclass, fun = if(class(inputclass) %in% c("character","numeric")){
  return(donnees[vargroupage %in% c(inputclass)])
}){
  do.call(fun, list(inputclass = inputclass))
}

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
    new_dt[vargroupage%in%variable, valgroupage := factor(valgroupage, levels = 1:4, labels = diplome)]
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
      var_ref<-diplome[4]
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



esperance <- function(maladie_chronique){
  
  esp_vie_filtered <- esp_vie %>% filter(Categorie == maladie_chronique)
  colnames(esp_vie_filtered)[2] = "DNVD"
  colnames(esp_vie_filtered)[4] = "EDV"
  plot <- ggplot(data = esp_vie_filtered, aes(x = DNVD,
                                              y = EDV),
                 group=Sante,color=Sante) +
    geom_line(aes(color = Sante, group = Sante)) +
    geom_point(aes(color = Sante)) +
    labs(title = paste("Inégalités d'espérance de vie dues au", maladie_chronique),
         x = "Niveau de vie de la population",
         y = "Espérance de vie ") +
    scale_x_continuous(breaks = 1:10, labels = richesse) +
    theme_minimal() +
    theme(legend.position = "right") + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(size = 12))
  
  return(plot)
}

#### fonction pour afficher les cartes 

donnees_cartes <- function(donnees,
                           inputemploi = 2,
                           inputdiplome =1,
                           inputage = "<30",
                           inputsexe = "F",
                           inputNVD = 1,
                           inputmaladie = "SUP_CV_CAT")
  
{ inegalite[varpartition %in% "FISC_REG_S"] ## On ne prend que les données sur les régions 
  
  sexe.table <- filter_var_Groupage(inegalite,"SEXE")[valgroupage == inputsexe]
  age.table <- filter_var_Groupage(inegalite,"classeAge10")[valgroupage == inputage]
  NVD.table <- filter_var_Groupage(inegalite,"FISC_NIVVIEM_E2015_S_moy_10")[valgroupage == inputNVD]
  emploi.table <- filter_var_Groupage(inegalite, "EAR_GS_S")[valgroupage == inputemploi]
  diplome.table <- filter_var_Groupage(inegalite, "EAR_DIPLR_S")[valgroupage == inputdiplome]
  
  new_data<-rbind(sexe.table,age.table,NVD.table,emploi.table,diplome.table)
  new_data <- new_data[cat %in% inputmaladie]
  
  incidence <- new_data[type == "incidence"]
  
  incidence<-incidence[, mean(txstanddir*100), by= "valpartition"][order(valpartition)]
  
  data_fr[,incidence_moyenne := NA]
  
  data_fr$incidence_moyenne[which(data_fr$numero_region %in% incidence$valpartition)] <- incidence$V1
  
  
  return(data_fr)}



carte_resume <- function(don){  
  p<-ggplot(t_geo, aes(fill = g_dir)) + 
    geom_sf() +
    facet_wrap(~ catlib, ncol = 4, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
    scale_fill_distiller(direction = 1,
                         palette = 7,
                         na.value = "grey20",
                         name = "ratio D1/D10") +
    ggtitle("Inégalités régionales de prévalence")
  return(p)}


carte_utilisateur <- function(don){
  
  return(hcmap("countries/fr/fr-all",
               data  = don,
               value = "incidence_moyenne",
               joinBy = c("hc-a2"),
               name = "moyenne du taux d'incidence standardisé  de la maladie",
               dataLabels = list(enabled = TRUE, format = '{point.name}'),
               borderColor = "#FAFAFA", borderWidth = 0.1,
               tooltip = list(valueDecimals = 6,valueSuffix = "%"))
  )
  
}


#############présentation des libellés de vargroupage
libelle<-read.table("Donnees/libelles_er12432.csv",header = TRUE,sep=";")
libelle<-libelle[,1:3]

#############affichage d'un extrait de la base de donnée
extraitbdd<-incidence[1:20,]
