import React from "react";
import { func, string } from "prop-types";
import styled from "styled-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faMoon, faSun } from "@fortawesome/free-solid-svg-icons";
import { GlobalStyles } from "./global";

const ToggleContainer = styled.button`
  position: relative;
  display: flex;
  justify-content: space-between;
  background: ${({ theme }) => theme.gradient};
  width: 4rem;
  height: 2rem;
  margin: 0;
  border-radius: 30px;
  border: 2px solid ${({ theme }) => theme.toggleBorder};
  font-size: 0.5rem;
  padding: 0.5rem;
  overflow: hidden;
  cursor: pointer;
  svg {
    width: 1.5rem;
    height: auto;
    transition: all 0.3s linear;
    &:first-child {
      transform: ${({ lightTheme }) =>
        lightTheme ? "translateY(0)" : "translateY(100px)"};
    }
    &:nth-child(2) {
      transform: ${({ lightTheme }) =>
        lightTheme ? "translateY(-100px)" : "translateY(0)"};
    }
  }
`;

const Toggle = ({ theme, toggleTheme }) => {
  const isLight = theme === "light";

  return (
    <ToggleContainer lightTheme={isLight} onClick={toggleTheme}>
      <GlobalStyles />
      <FontAwesomeIcon icon={faSun} size="2x" color="yellow" />
      <FontAwesomeIcon icon={faMoon} size="2x" color="gray" />
    </ToggleContainer>
  );
};

Toggle.propTypes = {
  toggleTheme: func.isRequired,
  theme: string.isRequired
};

export default Toggle;
