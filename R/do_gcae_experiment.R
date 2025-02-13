#' Do a full `GCAE` experiment
#'
#' Do a full `GCAE` experiment
#' @inheritParams default_params_doc
#' @return a `gcae_experiment_results`
#' @author Richèl J.C. Bilderbeek
#' @export
do_gcae_experiment <- function( # nolint indeed a function that is too complex
  gcae_experiment_params,
  verbose = FALSE
) {
  plinkr::check_verbose(verbose)
  # 'gcae_experiment_params' is checked in this function
  gcaer::check_input_files_are_present(gcae_experiment_params)

  analyse_epochs <- gcae_experiment_params$analyse_epochs
  resume_froms <- c(0, analyse_epochs[-length(analyse_epochs)])
  n_epochs <- analyse_epochs - resume_froms

  n_neurons_in_latent_layer <- gcaer::get_n_neurons_in_latent_layer(
    gcae_experiment_params
  )

  # Results
  losses_from_project_table <- NA # Will be overwritten by each last project
  genotype_concordances_table <- NA # Will be overwritten by each last project
  score_per_pops_list <- list()
  scores_list <- list()
  phenotype_predictions_list <- list()
  train_filenames <- NA # Will be overwritten by each last training session

  for (i in seq_along(n_epochs)) {

    if (verbose) {
      message(i, "/", length(analyse_epochs))
    }
    # Train to this 'epochs'

    # 'train_filenames' will overwrite/update the same files every epoch
    train_filenames <- gcae_train_more(
      gcae_setup = gcae_experiment_params$gcae_setup,
      resume_from = resume_froms[i],
      epochs = n_epochs[i],
      save_interval = n_epochs[i],
      verbose = verbose,
      gcae_options = gcae_experiment_params$gcae_options
    )
    if (verbose) {
      message(paste(train_filenames, collapse = "\n"))
    }
    project_filenames <- character()
    if (n_neurons_in_latent_layer == 2) {
      project_filenames <- gcae_project(
        gcae_setup = gcae_experiment_params$gcae_setup,
        gcae_options = gcae_experiment_params$gcae_options,
        verbose = verbose
      )
    }
    if (verbose) {
      message(
        "Start of 'parse_project_files', for 'project_filenames': \n * ",
        paste(project_filenames, collapse = "\n * ")
      )
    }
    if (length(project_filenames) > 0) {
      t_project_results <- gcaer::parse_project_files(project_filenames)
      # Will be overwritten each cycle, by tibbles with more info
      losses_from_project_table <- t_project_results$losses_from_project_table
      genotype_concordances_table <- t_project_results$genotype_concordances_table # nolint indeed a long line
    }

    if (gcae_experiment_params$gcae_setup$superpops == "") {
      if (verbose) {
        message("No labels, hence no GCAE evaluate")
      }
      # No sub/populations, hence no metrics
      testthat::expect_true(gcae_experiment_params$metrics == "")
    } else {
      testthat::expect_true(gcae_experiment_params$metrics != "")
      evaluate_filenames <- gcaer::gcae_evaluate(
        gcae_setup = gcae_experiment_params$gcae_setup,
        gcae_options = gcae_experiment_params$gcae_options,
        metrics = gcae_experiment_params$metrics,
        epoch = analyse_epochs[i],
        verbose = verbose
      )
      evaluate_results <- gcaer::parse_evaluate_filenames(
        evaluate_filenames = evaluate_filenames,
        epoch = analyse_epochs[i]
      )
      evaluate_results$t_score_per_pop$epoch <- analyse_epochs[i]
      evaluate_results$t_scores$epoch <- analyse_epochs[i]
      score_per_pops_list[[i]] <- evaluate_results$t_score_per_pop
      scores_list[[i]] <- evaluate_results$t_scores
    }

    # Evaluate the phenotype
    if (gcae_experiment_params$gcae_setup$pheno_model_id != "") {
      phenotype_predictions_table <- gcaer::evaluate_phenotype_prediction(
        gcae_experiment_params = gcae_experiment_params,
        epoch = analyse_epochs[i],
        verbose = verbose
      )
      phenotype_predictions_table$epoch <- analyse_epochs[i]
      phenotype_predictions_list[[i]] <- phenotype_predictions_table
    }
  }

  if (tibble::is_tibble(losses_from_project_table)) {
    if (nrow(losses_from_project_table) !=
      length(gcae_experiment_params$analyse_epochs)
    ) {
      stop(
        "There is less projected then intended. \n",
        "Tip 1: this is likely to be due to a continued run. \n",
        "Tip 2: run 'gcaer::clean_gcaer_tempfolder()' \n",
        "nrow(losses_from_project_table): ",
          nrow(losses_from_project_table), " \n",
        "length(gcae_experiment_params$analyse_epochs): ",
          length(gcae_experiment_params$analyse_epochs), " \n",
        "head(losses_from_project_table): \n",
          paste0(knitr::kable(utils::head(losses_from_project_table)), "\n"),
        "head(gcae_experiment_params$analyse_epochs): \n",
          paste0(utils::head(gcae_experiment_params$analyse_epochs), "\n"), "\n"
      )
    }
    testthat::expect_equal(
      nrow(losses_from_project_table),
      length(gcae_experiment_params$analyse_epochs)
    )
    losses_from_project_table$epoch <- gcae_experiment_params$analyse_epochs
  }
  if (tibble::is_tibble(genotype_concordances_table)) {
    testthat::expect_equal(
      nrow(genotype_concordances_table),
      length(gcae_experiment_params$analyse_epochs)
    )
    genotype_concordances_table$epoch <- gcae_experiment_params$analyse_epochs
  }
  score_per_pop_table <- dplyr::bind_rows(score_per_pops_list)

  phenotype_predictions_table <- NA
  nmse_in_time_table <- NA
  r_squared_in_time_table <- NA
  if (gcae_experiment_params$gcae_setup$pheno_model_id != "") {
    phenotype_predictions_table <- dplyr::bind_rows(phenotype_predictions_list)
    nmse_in_time_table <- gcaer::calc_nmse_from_phenotype_predictions(
      phenotype_predictions_table
    )
    r_squared_in_time_table <- gcaer::calc_r_squared_from_phenotype_predictions(
      phenotype_predictions_table
    )
  }
  scores_table <- dplyr::bind_rows(scores_list)
  train_results <- gcaer::parse_train_filenames(
    train_filenames = train_filenames
  )

  gcae_experiment_results <- list(
    score_per_pop_table = score_per_pop_table,
    scores_table = scores_table,
    genotype_concordances_table = genotype_concordances_table,
    phenotype_predictions_table = phenotype_predictions_table,
    nmse_in_time_table = nmse_in_time_table,
    r_squared_in_time_table = r_squared_in_time_table,
    train_times_table = train_results$train_times_table,
    losses_from_train_t_table = train_results$losses_from_train_t_table,
    losses_from_train_v_table = train_results$losses_from_train_v_table
  )
  if (gcae_experiment_params$gcae_setup$pheno_model_id == "") {
    gcae_experiment_results$phenotype_predictions_table <- NULL
    gcae_experiment_results$nmse_in_time_table <- NULL
    gcae_experiment_results$r_squared_in_time_table <- NULL
  }
  if ("check" == "very much") {
    gcaer::check_gcae_experiment_results(gcae_experiment_results)
  }

  gcae_experiment_results
}
