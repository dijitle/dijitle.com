import React from "react";
import { createRoot } from "react-dom/client";

const App = () => (
  <div style={{ fontFamily: "sans-serif", padding: "2rem" }}>
    <h1>Dijitle</h1>
    <p>Website running.</p>
  </div>
);

createRoot(document.getElementById("root")).render(<App />);
