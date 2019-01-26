import 'package:flutter/material.dart';
import 'package:rapido/rapido.dart';
import 'dart:convert';

void main() => runApp(Quiz());

// This is the normal boilerplace
class Quiz extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QuizHomePage(),
    );
  }
}

class QuizHomePage extends StatefulWidget {
  QuizHomePage({Key key}) : super(key: key);

  // Here I am creating a documentList object from the rapido
  // package. This will handle local persistence and create the
  // the datastructure to make the rest of the code easier to
  // write
  final DocumentList documentList = DocumentList("Q+A");

  @override
  _QuizHomePageState createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  int currentQuestion = 0;

  @override
  void initState() {
    // The DocumentList loads data from the device asyncronously
    // so there is some extra code to check if the data is
    // not yet loaded, or if it has never been loaded
    if (widget.documentList.length == 0 &&
        widget.documentList.documentsLoaded) {
      // no documents loaded, this is a first run
      loadFromJson();
    }

    super.initState();
  }

  // This function loades the data from the qa.json file. I wrote it
  // this way to make it easy to change to downloading the data from
  // a server instead. In that case, you can replace this function with
  // a function that fetches the data. The DocumentList will automatically
  // persist the data locally once fetched. If you don't want to download
  // the data from a server, you can just change qa.json the way you want.
  // WARNING: to make the example easier, I aded the images to pubspec.yaml.
  // You can replace the code with pointers to images on the web, or you can
  // download the images and refer to the paths where you downloaded them.
  loadFromJson() async {
    String data =
        await DefaultAssetBundle.of(context).loadString("assets/qa.json");
    List<dynamic> jsonResult = json.decode(data);
    List<Map<String, dynamic>> qa = List<Map<String, dynamic>>.from(jsonResult);
    print(qa);
    qa.forEach((dynamic obj) {
      print(obj);
      widget.documentList.add(Document(initialValues: obj));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Similar to above, this code is necessary because DocumentList
    // loads the local data asyncronously. This code waits for the
    // loading to be completed and checks if it is a first run. If it
    // is a fist run, it loads the data. SetState then tells the widget
    // to call build again after the documents are loaded. Note that
    // if the DocumentList is already loaded, onLoadComplete is not called
    // so the widget does not rebuild unnecessarily if the data is
    // already loaded.
    widget.documentList.onLoadComplete = (DocumentList list) {
      if (list.length == 0) {
        // no documents loaded, this is a first run
        loadFromJson();
      }
      setState(() {});
    };
    // if the documents are still loading from storage
    // just return an empty container and wait for the
    // documents to finish loading. This is only useful because
    // it keeps errors from polluting the debug output.
    if (!widget.documentList.documentsLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    // This is to build the row of buttons along the top as per
    // the example.
    IndexRow indexRow = IndexRow(
      documentList: widget.documentList,
      onIndexChanged: (int newIndex) {
        setState(() {
          currentQuestion = newIndex;
        });
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz"),
      ),
      body: Column(
        children: [
          indexRow,
          QuestionWidget(
            documentList: widget.documentList,
            currentQuestionIndex: currentQuestion,

            // onQuestionAnswered is called when the user has
            // clicked the forward button in the feedback widget.
            // Usually the app will go on to the next question, but
            // if the user is on the last question, it should do 
            // something else.
            onQuestionAnswered: (int oldIndex) {
              int newIndex = oldIndex + 1;
              if (newIndex < widget.documentList.length) {
                setState(() {
                  currentQuestion = newIndex;
                });
              } else {
                // You probably want to make some kind of nice completion
                // screen here. You can use the DocumentList to mine for
                // interesting statistics, etc...
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Scaffold(
                        body: Text("Show some kind of completion screen here"),
                      );
                    });
              }
            },
          )
        ],
      ),
    );
  }
}

/// Widget to show the selector for questions along the top 
/// as per the example
class IndexRow extends StatelessWidget {
  final Function onIndexChanged;
  final DocumentList documentList;

  const IndexRow({Key key, this.onIndexChanged, this.documentList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: getChildren(),
    );
  }

  List<Widget> getChildren() {
    List<Widget> widgets = [];
    for (int i = 0; i < documentList.length; i++) {
      widgets.add(RaisedButton(
        child: Text((i + 1).toString()),
        onPressed: () {
          onIndexChanged(i);
        },
      ));
    }
    return widgets;
  }
}

/// The widget to display a single question
class QuestionWidget extends StatelessWidget {
  final DocumentList documentList;
  final int currentQuestionIndex;
  final Function onQuestionAnswered;

  const QuestionWidget(
      {Key key,
      this.documentList,
      this.currentQuestionIndex,
      this.onQuestionAnswered})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Build the list of widgets to pass into the column
    List<Widget> widgets = <Widget>[
      Image(
        image:
            // as noted above, you may need to change the ImageProvider depending
            // on where you store the images.
            AssetImage("assets/${documentList[currentQuestionIndex]["image"]}"),
      ),
      Text(documentList[currentQuestionIndex]["question"]),
    ];

    // This block of code creates a button for each answer
    List<String> options =
        List<String>.from(documentList[currentQuestionIndex]["options"]);
    for (int i = 0; i < options.length; i++) {
      widgets.add(
        RaisedButton(
          child: Text(
            "${(i + 1).toString()}. ${options[i]}.",
          ),

          // When the user chooses an answer, this block of code
          // updates the DocumentList with the results. The 
          // DocumentList automatically persists the results.
          onPressed: () {
            // record the guess and the result for the question
            bool correct =
                (documentList[currentQuestionIndex]["answer"] == options[i]);
            if (documentList[currentQuestionIndex]["guesses"] == null) {
              documentList[currentQuestionIndex]["guesses"] = 1;
            } else {
              documentList[currentQuestionIndex]["guesses"] += 1;
            }
            if (documentList[currentQuestionIndex]["correct-guesses"] == null) {
              documentList[currentQuestionIndex]["correct-guesses"] = 0;
            }
            if (correct) {
              documentList[currentQuestionIndex]["correct-guesses"] += 1;
            }

            // Show the FeedbackWidget. Wait for the user to dismiss the
            // dialog, and then trigger onQuestionAnswered (in the then
            // block). Pass in the Document for the specific question, which
            // has all of the data needed for the feedback, because it was
            // updated in the code block above
            showDialog<int>(
                    context: context,
                    builder: ((BuildContext context) {
                      return FeedbackWidget(
                        document: documentList[currentQuestionIndex],
                        guess: options[i],
                      );
                    }))
                .then((dynamic val) {
              onQuestionAnswered(currentQuestionIndex);
            });
          },
        ),
      );
    }

    return Column(
      children: widgets,
    );
  }
}

/// The widget to display after the user has answered a question.
/// It receives the document and the answer that user provided
/// and provides appropriate feedback. It will be shown as a dialog
/// so it has a forward button that will pop the navigation, effectively
/// dismissing the dialog.
class FeedbackWidget extends StatelessWidget {
  final Document document;
  final String guess;

  const FeedbackWidget({Key key, this.document, this.guess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool correct = (document["answer"] == guess);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.forward),
        onPressed: (() {
          Navigator.pop(context);
        }),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Icon(correct ? Icons.check : Icons.remove_circle,
                size: 100.0, color: correct ? Colors.green : Colors.red),
          ),
          Text(correct
              ? "Correct!"
              : "Incorrect, you guessed $guess, but the correct answer is ${document["answer"]}."),
          Text(document["explanation"]),
          Text(
              "${(document["correct-guesses"].toDouble() / document["guesses"].toDouble() * 100).toString()}%"),
        ],
      ),
    );
  }
}
