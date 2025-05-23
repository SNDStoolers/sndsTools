% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{create_table_from_query}
\alias{create_table_from_query}
\title{Création d'une table à partir d'une requête SQL.}
\usage{
create_table_from_query(
  conn = NULL,
  output_table_name = NULL,
  query = NULL,
  overwrite = FALSE
)
}
\arguments{
\item{conn}{Connexion à la base de données}

\item{output_table_name}{Nom de la table de sortie}

\item{query}{Requête SQL}

\item{overwrite}{Logical. Indique si la table \code{output_table_name}
doit être écrasée dans le cas où elle existe déjà.}
}
\description{
Création d'une table à partir d'une requête SQL.
}
\details{
La fonction crée une table sous Oracle à partir d'une requête SQL.
Si la table \code{output_table_name} existe déjà, elle est écrasée si
le paramètre \code{overwrite} est TRUE.
}
