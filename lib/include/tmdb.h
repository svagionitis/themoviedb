/**
 * @file
 */

#pragma once

#include "tmdb-visibility.h"


TMDB_C_API_BEGIN

/** @brief Get the API key
 *
 * @return the API key
 *
 * The API key will be stored in a file or in an ENV variable.
 *
 */
TMDB_API
int tmdb_get_api_key(void);

/** @}  */

TMDB_C_API_END
