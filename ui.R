#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "Impact de la qualité de vie \r\n sur l'incidence des maladies"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Présentation", tabName = "presentation", icon = icon("dashboard")),
      menuItem("Risque relatif par région", tabName = "risque_region", icon = icon("chart-line")),
      menuItem("Synthèse des risques relatifs", tabName = "Risque_relatif", icon = icon("chart-bar")),
      menuItem("espérance de vie des maladies chroniques",tabName="Inegalite_esperance_maladies_chroniques", icon=icon("chart-line")),
      menuItem("Cartographie des risque",tabName="carte",icon = icon("map"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
    .scrollable-table {
      overflow-x: auto !important;
      max-width: 200% !important;
      max-height: 500px; !important
    }
  "))
    ),
    
    tabItems(
      # Premier onglet
      tabItem(tabName = "presentation",
              fluidRow(
                column(12,
                       # I : objet de l'application
                       tags$h1("Objet de l'application"),
                       
                       # I.1 : objectif
                       tags$h2("Objectif de l'application"),
                       tags$p("Cette application a été conçue dans le double objectif d'approfondir notre maîtrise de R Shiny et d'appliquer nos connaissances théoriques pour visualiser et interpréter des données de manière pertinente. Le thème de la santé publique a été choisi en raison de son importance et de sa pertinence dans le contexte actuel."), 
                       tags$p("À travers cette interface, nous souhaitons présenter de manière claire et concise des informations cruciales liées à l'incidence et à la prévalence de diverses maladies chroniques, en mettant l'accent sur leurs interactions avec des variables socio-démographiques spécifiques."),
                       tags$p("Ainsi, cette application est un complément ceux qui cherchent à comprendre l'étude Inégalités sociales face aux maladies chroniques (ER 1243) en visualisant les données associées d'une manière claire et interactive."),
                       
                       # I.1 : présentation de l'étude utilisée
                       tags$h2("Présentation de l'étude utilisée"),
                       tags$p(
                         "L'étude se concentre sur le taux d'incidence et de prévalence des maladies 
                         chroniques en fonction de diverses variables socio-démographiques telles que le sexe, 
                         l'âge, la région, le dixième de niveau de vie, le groupe socioprofessionnel et le diplôme. 
                         Cette étude a été menée pour la publication « Les maladies chroniques touchent plus souvent 
                         les personnes modestes et réduisent davantage leur espérance de vie », figurant dans la série 
                         \"Études et Résultats\" sous le numéro 1243. 
                         l'étude et la base de données sont présentées à cette ", 
                         tags$a(href="https://www.data.gouv.fr/fr/datasets/inegalites-sociales-face-aux-maladies-chroniques-er-1243/?fbclid=IwAR0W2p9SdFKz2z0TUdDv-YbWjEgq1z6ob93R1jv3Wfz0jmAgzanC8sRIoD0", "adresse"), "."
                       ),
                       
                       
                       # I.2 : définitions utiles
                       tags$h2("Définitions utiles"),
                       tags$p(tags$b("Taux d'incidence"), ": Cette définition décrit le nombre de nouveaux cas d'une maladie 
                                      dans une population donnée pendant une période de temps spécifiée."),
                       tags$p(tags$b("Prévalence"), ": Cette définition décrit la proportion d'individus dans une population 
                                      qui ont une caractéristique ou une condition donnée à un moment donné ou sur une période spécifiée."),
                       tags$p(tags$b("Risque relatif"), ": Cette définition décrit le ratio du risque de l'événement 
                                    (par exemple, développer une maladie) dans le groupe exposé au risque dans le groupe non exposé."),
                       
                       # I.2 cadrage méthodologique
                       tags$h2("Cadrage méthodologique"),
                       tags$p("Pour assurer la fiabilité et la pertinence de nos analyses, nous avons adopté une approche méthodologique rigoureuse."),
                       tags$ul(
                         tags$li("Taux d'incidence standardisé : L'utilisation du taux d'incidence standardisé nous a permis de neutraliser les effets des facteurs de confusion potentiels dans nos résultats. En ajustant selon certaines variables, notamment l'âge et le sexe, nous avons pu obtenir des estimations qui reflètent au mieux la réalité, indépendamment des distributions démographiques des populations étudiées."),
                         tags$li("Ratio du risque relatif : Nous avons opté pour le ratio du risque relatif comme mesure clé pour nos analyses exploratoires. Cette métrique a été choisie car elle offre une compréhension claire de la mesure dans laquelle un facteur spécifique peut augmenter ou diminuer le risque de maladie chronique."),
                         tags$li("Traitement des données manquantes : Confrontés à la problématique des données manquantes, courante dans les études épidémiologiques, nous avons adopté une approche de remplacement par la médiane. Cette technique permet d'imputer des valeurs en conservant la distribution générale des données, tout en minimisant l'impact des valeurs extrêmes.")
                       ),
                       tags$p("En combinant ces techniques et approches, nous avons veillé à ce que nos analyses soient à la fois robustes et représentatives des tendances réelles observées dans la population."),
                       
                       tags$h1("Description des données"),
                       tags$p("Les données que nous utilisons offrent une ventilation selon diverses variables socio-démographiques. Chaque donnée peut être trouvée dans la colonne 'varGroupage' et sa valeur correspondante dans la colonne 'valGroupage'. Voici une liste des variables disponibles :"),
                       tags$ul(
                         tags$li("Sexe (SEXE)"),
                         tags$li("Classe d'âge de 10 ans (classeAge10)"),
                         tags$li("Région (FISC_REG_S)"),
                         tags$li("Dixième de niveau de vie (FISC_NIVVIEM_E2015_S_moy_10)"),
                         tags$li("Groupe socioprofessionnel (EAR_GS_S)"),
                         tags$li("Diplôme (EAR_DIPLR_S)")
                       ),
                       actionButton("showTable","Voir le détail des libellés"),
                       tags$p("Le jeu de données comprend également les effectifs pondérés, les taux non standardisés, et les taux standardisés. Ces derniers sont obtenus par des méthodes directes et indirectes, avec des intervalles de confiance à 95%."),
                       actionButton("showextraitbdd","Voir la base de donnée"),
                       
                       # III : fonctionnalité de l'application
                         # Titre
                         tags$h1("Fonctionnalités de l'application R Shiny"),
                         
                         # Liste des fonctionnalités
                         tags$ul(
                           # Onglet Présentation
                           tags$li(tags$b("Présentation:"), " Cet onglet sert d'introduction à l'application et donne un aperçu général de l'étude et de ses objectifs."),
                           
                           # Onglet Risque relatif par région
                           tags$li(tags$b("Risque relatif par région:"), " C'est ici que vous pouvez explorer le risque relatif des maladies chroniques en fonction du niveau de richesse des individus. En utilisant le ", tags$b("dixième de la population la plus aisée"), " comme référence, cet onglet offre un aperçu visuel des inégalités de santé en fonction de la richesse à travers différentes régions."),
                           
                           # Onglet Synthèse des risques relatifs
                           tags$li(tags$b("Synthèse des risques relatifs:"), " Cette section est dédiée à une analyse globale des risques relatifs associés à différentes maladies, en fonction de plusieurs indicateurs de qualité de vie. Les utilisateurs peuvent personnaliser leur visualisation en sélectionnant des variables spécifiques liées à la qualité de vie, afin d'obtenir des insights sur les facteurs contribuant à ces risques."),
                           
                           # Onglet Espérance de vie des maladies chroniques
                           tags$li(tags$b("Espérance de vie des maladies chroniques:"), " L'onglet met en lumière l'espérance de vie des personnes atteintes de maladies chroniques par rapport à celles non atteintes. Il utilise un tableau de calcul pour montrer la différence d'espérance de vie en fonction du niveau de richesse pour chaque maladie. Cette visualisation aide à comprendre l'écart entre les personnes ayant des affections et celles sans, tout en mettant en évidence l'influence du niveau de richesse sur cette dynamique.")
                         ),
                       
                       # IV : modèle prédictif
                       tags$h1("Modèle prédictif"),
                       tags$p("Description de votre modèle prédictif...")
                )
              )
      ),
      # Deuxième onglet
      tabItem(tabName = "risque_region",
              fluidRow(
                column(2,
                       wellPanel(
                         checkboxGroupInput(inputId="region",label = "Choix de la région", 
                                            choices = c("Guadeloupe"=1, "Martinique"=2, "Guyane"=3, "La Reunion"=4, "Saint-Pierre et Miquelon"=5, "Mayotte"=6, "Saint-Barthélémy"=7, "Saint-Martin"=8,"Ile-de-France"=11, "Centre-Val de Loire"=24, "Bourgogne-Franche-Comté"=27, "Normandie"=28, "Hauts-de-France"=32, "Grand Est"=44, "Pays de la Loire"=52, "Bretagne"=53, "Nouvelle-Aquitaine"=75, "Occitanie"=76, "Auvergne-Rhône-Alpes"=84, "Provence-Alpes-Côte d'Azur"=93, "Corse"=94), 
                                            selected = 1
                         ),
                         selectInput(inputId="maladie", label="catégorie de maladie",
                                     choices=c("Maladies inflammatoires ou rares ou VIH ou SIDA",
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
                         )
                       )
                ),
                column(10, plotOutput("Graphique"))
              )
      ),
      # Troisième onglet
      tabItem(tabName = "Risque_relatif",
              fluidRow(
                column(2,
                       radioButtons(inputId="variable",label = "niveau d'éducation",
                                    choices =c("catégorie socio-professionnelle"="EAR_GS_S",
                                               "niveau d'éducation"="EAR_DIPLR_S",
                                               "niveau de richesse"="FISC_NIVVIEM_E2015_S_moy_10"
                                    ),
                                    selected = "EAR_GS_S"
                       )
                ),
                column(10, 
                       div(
                         style = "overflow-x: auto;", 
                         plotOutput("graphe_var", width = "120%", height = "1000px")
                       )
                )
              )
      ),
      # Quatrième onglet
      tabItem(tabName = "Inegalite_esperance_maladies_chroniques",
              fluidRow(
                column(2,
                       selectInput(inputId="maladie_chronique", label="catégorie de maladie chronique",
                                   choices=c("Diabète",                                       
                                             "Maladies cardioneurovasculaires",                
                                             "Maladies neurologiques ou dégénératives",       
                                             "Maladies psychiatriques",                        
                                             "Maladies respiratoires chroniques",             
                                             "Maladies du foie ou du pancréas",                
                                             "Cancers",
                                             "Toutes catégories confondues"
                                   )
                       )
                ),
                column(10, 
                       div(
                         style = "overflow-x: auto;", 
                         plotOutput("plot", width = "100%", height = "500px")
                       )
                )
              )
      )
    )
  )
)























###############################################
