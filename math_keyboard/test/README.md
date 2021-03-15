## Unit testing in math_keyboard

It should be obvious that we aim to unit test every possible unit in the
`math_keyboard` package. This ranges from the `tex2math` converter to (where
"unit tests" is used in the broader Flutter sense of widget tests) the math
field and keyboard.

On top of that, it should be noted that we have **internal test cases**
[@simpleclub][simpleclub] to verify that the math keyboard works in the way
we need it to when integrating (on the unit level) with proprietary systems.
This is to say that if you are missing a test case (you are wondering why it
is not covered), it might be that we have an internal test case that is not
included in this repo that makes us feel like that particalur case is covered.
Do feel free, however, to contribute any missing test cases in this repo as well
as they will always be more focused this way :)

[simpleclub]: https://github.com/simpleclub
