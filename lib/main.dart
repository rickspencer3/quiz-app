import 'package:flutter/material.dart';
import 'package:rapido/rapido.dart';
import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(Quiz());

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

  final DocumentList documentList = DocumentList("Q+A");

  @override
  _QuizHomePageState createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  int currentQuestion = 0;

  @override
  void initState() {
    if (widget.documentList.length == 0 &&
        widget.documentList.documentsLoaded) {
      // no documents loaded, this is a first run
      loadFromJson();
    }

    super.initState();
  }

  /// Initial Q+A data is kept in qa.json. This function runs on first run
  /// and initializes the DocumentList with the Q+A info. User success is
  /// then tracked in the DocumentList as well.
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
    print(widget.documentList);
  }

  @override
  Widget build(BuildContext context) {
    // if the document list is not yet loaded, then make sure
    // to rebuild after it is loaded
    widget.documentList.onLoadComplete = (DocumentList list) {
      if (list.length == 0) {
        // no documents loaded, this is a first run
        loadFromJson();
      }
      setState(() {});
    };
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
            index: currentQuestion,
          )
        ],
      ),
    );
  }
}

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

class QuestionWidget extends StatelessWidget {
  final DocumentList documentList;
  final int index;

  const QuestionWidget({Key key, this.documentList, this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = <Widget>[
      Image(
        image: AssetImage("assets/${documentList[index]["image"]}"),
      ),
      Text(documentList[index]["question"]),
    ];

    List<String> options = List<String>.from(documentList[index]["options"]);
    for (int i = 0; i < options.length; i++) {
      widgets.add(
        RaisedButton(
          child: Text(
            "${(i + 1).toString()}. ${options[i]}.",
          ),
          onPressed: () {
            // record the guess and the result for the question
            bool correct = (documentList[index]["answer"] == options[i]);
            if (documentList[index]["guesses"] == null) {
              documentList[index]["guesses"] = 1;
            } else {
              documentList[index]["guesses"] += 1;
            }
            if (documentList[index]["correct-guesses"] == null) {
              documentList[index]["correct-guesses"] = 0;
            }
            if (correct) {
              documentList[index]["correct-guesses"] += 1;
            }

            Navigator.push(context, MaterialPageRoute(
              builder: (BuildContext context) {
                return FeedbackWidget(
                    document: documentList[index], guess: options[i]);
              },
            ));
          },
        ),
      );
    }

    return Column(
      children: widgets,
    );
  }
}

class FeedbackWidget extends StatelessWidget {
  final Document document;
  final String guess;

  const FeedbackWidget({Key key, this.document, this.guess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool correct = (document["answer"] == guess);
    return Scaffold(
      appBar: AppBar(title: Text("Result")),
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
