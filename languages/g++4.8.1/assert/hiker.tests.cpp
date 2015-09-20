#include "hiker.hpp"
#include <cassert>
#include <iostream>

static void life_the_universe_and_everything()
{
    assert(answer() == 42);
}

int main()
{
    life_the_universe_and_everything();
    std::cout << "All tests passed";
}
