#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#



###############
#rshiny#
###############

server<-function(input, output, session) {
  
  data1 <- reactive(donnees_cartes(inegalite,
                                   input$emploi,
                                   input$diplome,
                                   input$age,
                                   input$sexe,
                                   input$NVD,
                                   input$maladie))
  
  data2 <- reactive(donnees_cartes(inegalite, 
                                   input$emploi2,
                                   input$diplome2,
                                   input$age2,
                                   input$sexe2,
                                   input$NVD2,
                                   input$maladie2))
  
  
  output$Graphique <- renderPlot({
    extraction(input$region, input$pathologie)
  })
  output$graphe_var<-renderPlot({
    choixvariable(input$variable)
  })
  output$plot<-renderPlot({
    esperance(input$maladie_chronique)
  })
  output$libelle_table <- renderTable(libelle)
  
  observeEvent(input$showTable, {
    showModal(modalDialog(
      title = "Description des libellés",
      tableOutput("libelle_table"),
      footer = tagList(
        modalButton("Fermer")
      ),
      size = "l" # taille large pour le dialogue
    ))
  })
  output$extrait_table_ui <- renderUI({
    tags$div(class = "scrollable-table",
             tableOutput("extraitbdd")
    )
  })
  
  output$extraitbdd <- renderTable({
    extraitbdd
  })
  
  observeEvent(input$showextraitbdd, {
    showModal(modalDialog(
      title = "Description des données",
      uiOutput("extrait_table_ui"),
      footer = tagList(
        modalButton("Fermer")
      ),
      size = "l"
    ))
  })
  output$carteresume <- renderPlot({
    carte_resume(t_geo)
    
  })
  
  output$titrecarte1 <- renderText({
    
    paste("Carte du taux d'incidence moyen standardisé pour la maladie chroniques:",
          inegalite$catlib[which( inegalite$cat == input$maladie)][1]
          
    )
  })
  output$titrecarte2 <- renderText({
    paste("Carte du taux d'incidence moyen standardisé pour la maladie chronique:",
          inegalite$catlib[which( inegalite$cat == input$maladie2)][1])
  })
  
  output$plot1 <- renderHighchart({
    input$Carte1
    isolate({
      x <- data1()
      carte_utilisateur(x)
    })
  })
  
  
  output$plot2 <- renderHighchart({
    input$Carte2
    isolate({
      x2 <- data2()
      carte_utilisateur(x2)
      
    })
  })
  
}

