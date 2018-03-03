library(shiny)
library(shinydashboard)
library(keras)


function(input, output, session) {
  pathValues <- reactiveValues(path_train=NULL, path_test=NULL, path_val=NULL, path_pred=NULL)

  #pathValues <- reactiveValues(path_train='~/Downloads/invasive_species_data/train/train', path_test='~/Downloads/invasive_species_data/train/test', path_val='~/Downloads/invasive_species_data/train/validation', path_pred='~/Downloads/invasive_species_data/container_test_small_sample/')

  output$myImage <- renderImage({
    list(src = input$newimg$datapath)

  })

  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$train_dir
    },
    handlerExpr = {
      if (input$train_dir > 0) {
        # condition prevents handler execution on initial app launch

        # launch the directory selection dialog with initial path read from the widget
        path_train = choose.dir(default = readDirectoryInput(session, 'train_dir'))

        # update the widget value
        updateDirectoryInput(session, 'train_dir', value = path_train)

        # store path
        pathValues$path_train <- path_train
      }
    }
  )
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$test_dir
    },
    handlerExpr = {
      if (input$test_dir > 0) {
        # condition prevents handler execution on initial app launch

        # launch the directory selection dialog with initial path read from the widget
        path_test = choose.dir(default = readDirectoryInput(session, 'test_dir'))

        # update the widget value
        updateDirectoryInput(session, 'test_dir', value = path_test)

        # store path
        pathValues$path_test <- path_test
      }
    }
  )
  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$val_dir
    },
    handlerExpr = {
      if (input$val_dir > 0) {
        # condition prevents handler execution on initial app launch

        # launch the directory selection dialog with initial path read from the widget
        path_val = choose.dir(default = readDirectoryInput(session, 'val_dir'))

        # update the widget value
        updateDirectoryInput(session, 'val_dir', value = path_val)

        # store path
        pathValues$path_val <- path_val
      }
    }
  )

  observeEvent(
    ignoreNULL = TRUE,
    eventExpr = {
      input$pred_dir
    },
    handlerExpr = {
      if (input$pred_dir > 0) {
        # condition prevents handler execution on initial app launch

        # launch the directory selection dialog with initial path read from the widget
        path_pred = choose.dir(default = readDirectoryInput(session, 'pred_dir'))

        # update the widget value
        updateDirectoryInput(session, 'pred_dir', value = path_pred)

        # store path
        pathValues$path_pred <- path_pred

        print(pathValues)
      }
    }
  )

  observeEvent(input$do, {

    progress <- shiny::Progress$new()


    progress$set(message = "Modeling", value = 0)

    train_dir <- pathValues$path_train
    test_dir <- pathValues$path_test
    validation_dir <- pathValues$path_val
    pred_dir <- pathValues$path_pred

    conv_base <- application_vgg16(
      weights = "imagenet",
      include_top = FALSE,
      input_shape = c(150, 150, 3)
    )


    model <- keras_model_sequential() %>%
      conv_base %>%
      layer_flatten() %>%
      layer_dense(units = 256, activation = 'relu') %>%
      layer_dense(units = 1, activation = 'sigmoid')

    freeze_weights(conv_base)

    train_datagen = image_data_generator(
      rescale = 1/255,
      rotation_range = 40,
      width_shift_range = 0.2,
      height_shift_range = 0.2,
      shear_range = 0.2,
      zoom_range = 0.2,
      horizontal_flip = TRUE,
      fill_mode = "nearest"
    )

    # Note that the validation data shouldn't be augmented!
    test_datagen <- image_data_generator(rescale = 1/255)

    train_generator <- flow_images_from_directory(
      train_dir,                  # Target directory
      train_datagen,              # Data generator
      target_size = c(150, 150),  # Resizes all images to 150 × 150
      batch_size = 20,
      class_mode = "binary"       # binary_crossentropy loss for binary labels
    )

    validation_generator <- flow_images_from_directory(
      validation_dir,
      test_datagen,
      target_size = c(150, 150),
      batch_size = 20,
      class_mode = "binary"
    )

    progress$inc(1/3, detail = "Training")

    model %>% compile(
      loss = "binary_crossentropy",
      optimizer = optimizer_rmsprop(lr = 2e-5),
      metrics = c("accuracy")
    )

    history <- model %>% fit_generator(
      train_generator,
      steps_per_epoch = input$steps_epoch,
      epochs = input$num_epoch,
      validation_data = validation_generator,
      validation_steps = input$steps_epoch
    )

    test_generator <- flow_images_from_directory(
      test_dir,
      test_datagen,
      target_size = c(150, 150),
      batch_size = 20,
      class_mode = "binary"
    )

    batch_predict_generator <- flow_images_from_directory(
      pred_dir,
      test_datagen,
      target_size = c(150, 150),
      batch_size = length(list.files(paste0(pred_dir, "/data_for_prediction"))),
      class_mode = "binary"
    )

    output$viz <- renderPlot({
      progress$inc(1/3, detail = "Predicting")
      plot(history, main="Model training history")
    })

    output$results <- renderText({
      result <- model %>% evaluate_generator(test_generator, steps = 2)
      paste( unlist(result), collapse = '\n')
    })

    output$batch_predict <- renderDataTable({
      result_scores = predict_generator(model, batch_predict_generator, steps = 1, verbose = 1)
      file_names = list.files(paste0(pred_dir, "/data_for_prediction"))
      result <- data.frame(scores = result_scores, names = file_names)
      on.exit(progress$close())
      progress$inc(1/3, detail = "Finished")
      result

    })



    # output$image_classify <- renderText({
    #   inFile <- input$newimg
    #   image_path <- inFile$datapath
    #
    #   img <- image_load(image_path, target_size = c(150, 150))
    #   img_tensor <- image_to_array(img)
    #   img_tensor <- array_reshape(img_tensor, c(1, 150, 150, 3))
    #   img_tensor <- img_tensor / 255
    #   print(predict_proba(model, img_tensor))
    #
    # })


  })


}
