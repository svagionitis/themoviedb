#include "unity.h"

#include "tmdb-compiler.h"
#include "tmdb.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_Is_1(void)
{
    TEST_ASSERT_EQUAL_INT(1, tmdb_get_api_key());
}

int main(void)
{
    UNITY_BEGIN();

    RUN_TEST(test_Is_1);

    return UNITY_END();
}
