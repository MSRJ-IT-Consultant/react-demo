import { useState } from "react";
import "./App.css";

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="app">
      <h1>Hello DevSecOps World 🚀</h1>
      <p>GitHub Actions msrj.xyz@gmail.com</p>

      <div className="card">
        <button onClick={() => setCount(count + 1)}>
          Clicked {count} times
        </button>
      </div>
    </div>
  );
}

export default App;
