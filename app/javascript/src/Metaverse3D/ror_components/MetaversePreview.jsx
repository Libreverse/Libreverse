import React, { useEffect, useState } from "react";

const MetaversePreview = (props) => {
    const [hydrated, setHydrated] = useState(false);

    useEffect(() => {
        setHydrated(true);
    }, []);

    return (
        <div>
            <h2>Metaverse Preview</h2>
            <p>Hello, {props.name || "Explorer"}!</p>
            <p
                style={{
                    color: hydrated ? "green" : "red",
                    fontWeight: "bold",
                }}
            >
                {hydrated ? "Hydrated ✅" : "Server Rendered"}
            </p>
        </div>
    );
};

export default MetaversePreview;
