let express = require("express");
let app = express();

app.get("/", (req, res) => {
  res.send("Hello from Terraform + Docker + Azure!");
});

app.listen(3000, () => {
  console.log("App running on port 3000");
});
