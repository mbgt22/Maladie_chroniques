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
  output$Graphique <- renderPlot({
    extraction(input$region, input$maladie)
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
  
}

